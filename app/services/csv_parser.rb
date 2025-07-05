require 'roo'

class CsvParser
  REQUIRED_HEADERS = %w[sku name regular_price].freeze
  OPTIONAL_HEADERS = %w[price description short_description stock_quantity weight].freeze
  ALLOWED_FORMATS = %w[csv xlsx xls ods].freeze
  MAX_FILE_SIZE = 10.megabytes

  attr_reader :filename, :total_rows, :headers

  def initialize(file)
    @file = file
    @filename = file.original_filename
    @spreadsheet = nil
  end

  def parse
    validate_file
    open_spreadsheet
    validate_headers
    parse_products
  rescue => e
    Rails.logger.error("CSV Parse Error: #{e.message}")
    raise "Parse error: #{e.message}"
  ensure
    @spreadsheet&.close if @spreadsheet.respond_to?(:close)
  end

  def preview(limit = 5)
    validate_file
    open_spreadsheet
    validate_headers

    products = []
    rows_to_process = [@spreadsheet.last_row, @headers_row + limit].min

    (@headers_row + 1..rows_to_process).each do |row_num|
      row_data = extract_row_data(row_num)
      next if row_data.values.all?(&:blank?)

      products << sanitize_row_data(row_data)
    end

    {
      products: products,
      total_rows: @total_rows,
      headers: @headers,
      filename: @filename
    }
  end

  private

  def validate_file
    raise "No file provided" unless @file
    raise "File is too large (max #{MAX_FILE_SIZE / 1.megabyte}MB)" if @file.size > MAX_FILE_SIZE

    extension = File.extname(@filename).downcase.delete('.')
    unless ALLOWED_FORMATS.include?(extension)
      raise "Unsupported file format. Allowed: #{ALLOWED_FORMATS.join(', ')}"
    end
  end

  def open_spreadsheet
    case File.extname(@filename).downcase
    when '.csv'
      @spreadsheet = Roo::CSV.new(@file.path)
    when '.xlsx'
      @spreadsheet = Roo::Excelx.new(@file.path)
    when '.xls'
      @spreadsheet = Roo::Excel.new(@file.path)
    when '.ods'
      @spreadsheet = Roo::OpenOffice.new(@file.path)
    else
      raise "Unsupported file format"
    end

    @total_rows = @spreadsheet.last_row
    raise "File appears to be empty" if @total_rows < 2 # At least header + 1 data row
  end

  def validate_headers
    # Find header row (usually first row, but could be different)
    @headers_row = find_header_row
    raise "Could not find valid headers in file" unless @headers_row

    @headers = normalize_headers(@spreadsheet.row(@headers_row))

    missing_headers = REQUIRED_HEADERS - @headers.keys.map(&:to_s)
    if missing_headers.any?
      raise "Missing required columns: #{missing_headers.join(', ')}. Found: #{@headers.keys.join(', ')}"
    end
  end

  def find_header_row
    # Check first few rows for headers
    (1..[@spreadsheet.last_row, 5].min).each do |row_num|
      row = @spreadsheet.row(row_num)
      next if row.all?(&:blank?)

      headers = normalize_headers(row)
      if (REQUIRED_HEADERS - headers.keys.map(&:to_s)).empty?
        return row_num
      end
    end
    nil
  end

  def normalize_headers(header_row)
    headers = {}
    header_row.each_with_index do |header, index|
      next if header.blank?

      # Normalize header names
      normalized = header.to_s.downcase.strip
                         .gsub(/\s+/, '_')           # spaces to underscores
                         .gsub(/[^\w]/, '')          # remove special chars
                         .gsub(/^_+|_+$/, '')        # remove leading/trailing underscores

      # Map common variations
      normalized = map_header_variations(normalized)

      headers[normalized.to_sym] = index if normalized.present?
    end
    headers
  end

  def map_header_variations(header)
    mapping = {
      'product_name' => 'name',
      'title' => 'name',
      'product_title' => 'name',
      'cost' => 'regular_price',
      'price' => 'regular_price',
      'amount' => 'regular_price',
      'product_code' => 'sku',
      'code' => 'sku',
      'item_code' => 'sku',
      'stock' => 'stock_quantity',
      'inventory' => 'stock_quantity',
      'qty' => 'stock_quantity',
      'quantity' => 'stock_quantity'
    }

    mapping[header] || header
  end

  def parse_products
    products = []

    (@headers_row + 1..@spreadsheet.last_row).each do |row_num|
      row_data = extract_row_data(row_num)

      # Skip empty rows
      next if row_data.values.all?(&:blank?)

      begin
        product_data = sanitize_row_data(row_data)
        products << product_data if product_data[:sku].present? || product_data[:name].present?
      rescue => e
        Rails.logger.warn("Skipping row #{row_num}: #{e.message}")
        next
      end
    end

    raise "No valid products found in file" if products.empty?
    products
  end

  def extract_row_data(row_num)
    row = @spreadsheet.row(row_num)
    data = {}

    @headers.each do |header, col_index|
      data[header] = row[col_index]
    end

    data
  end

  def sanitize_row_data(row_data)
    {
      sku: sanitize_string(row_data[:sku]),
      name: sanitize_string(row_data[:name]),
      regular_price: parse_price(row_data[:regular_price] || row_data[:price]),
      description: sanitize_text(row_data[:description]),
      short_description: sanitize_text(row_data[:short_description]),
      stock_quantity: parse_integer(row_data[:stock_quantity]),
      weight: parse_decimal(row_data[:weight])
    }.compact
  end

  def sanitize_string(value)
    return nil if value.blank?
    value.to_s.strip.presence
  end

  def sanitize_text(value)
    return nil if value.blank?
    # Clean up text, remove excessive whitespace
    value.to_s.strip.gsub(/\s+/, ' ').presence
  end

  def parse_price(value)
    return nil if value.blank?

    # Handle different price formats
    case value
    when Numeric
      value.to_f
    when String
      # Remove currency symbols and convert
      cleaned = value.gsub(/[^\d.,]/, '')
      # Handle comma as decimal separator (European format)
      cleaned = cleaned.tr(',', '.') if cleaned.count('.') == 0 && cleaned.count(',') == 1
      Float(cleaned) rescue nil
    else
      nil
    end
  end

  def parse_integer(value)
    return nil if value.blank?

    case value
    when Numeric
      value.to_i
    when String
      Integer(value.gsub(/[^\d]/, '')) rescue nil
    else
      nil
    end
  end

  def parse_decimal(value)
    return nil if value.blank?

    case value
    when Numeric
      value.to_f
    when String
      Float(value.gsub(/[^\d.]/, '')) rescue nil
    else
      nil
    end
  end
end