class CsvParser
  attr_reader :filename, :total_rows, :valid_count, :invalid_count

  def initialize(file)
    @file = file
    @filename = file.respond_to?(:original_filename) ? file.original_filename : File.basename(file)
    @total_rows = 0
    @valid_count = 0
    @invalid_count = 0
  end

  def parse
    validate_file
    products = []

    CSV.foreach(@file, headers: true) do |row|
      @total_rows += 1

      next if row.to_h.values.all?(&:blank?)

      product = create_product_from_row(row)

      if product.valid?
        @valid_count += 1
        products << product
        Rails.logger.info("Valid product: #{product.sku} - #{product.name}")
      else
        @invalid_count += 1
        Rails.logger.error("Invalid product row #{@total_rows}: #{product.errors.full_messages.join(', ')}")
        products << product
      end
    end

    log_summary
    products
  end

  def summary
    {
      filename: @filename,
      total_rows: @total_rows,
      valid_count: @valid_count,
      invalid_count: @invalid_count,
      success_rate: @total_rows > 0 ? (@valid_count.to_f / @total_rows * 100).round(1) : 0
    }
  end

  private

  def validate_file
    @file_path = @file.respond_to?(:path) ? @file.path : @file

    raise "File not found" unless File.exist?(@file_path)
    raise "File is empty" if File.zero?(@file_path)
    raise "File too large (max 10MB)" if File.size(@file_path) > 10.megabytes
  end

  def create_product_from_row(row)
    Product.new(
      sku: sanitize_value(row["SKU"]),
      name: sanitize_value(row["Name"]),
      regular_price: parse_price(row["Regular Price"] || row["Price"]),
    )
  end

  def sanitize_value(value)
    value&.to_s&.strip&.presence
  end

  def parse_price(value)
    return nil if value.blank?

    # Remove currency symbols and convert to decimal
    cleaned = value.to_s.gsub(/[^\d.]/, '')
    cleaned.present? ? cleaned.to_f : nil
  end

  def log_summary
    Rails.logger.info("CSV Parse Summary: #{@total_rows} total, #{@valid_count} valid, #{@invalid_count} invalid")
  end
end