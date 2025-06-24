require "roo"

module Products
  class ParsePriceFile
    class MissingColumnsError < StandardError; end
    class InvalidFileFormatError < StandardError; end

    def self.call(path)
      new(path).call
    end

    def initialize(path)
      @path = path
      @price_file = nil
      @errors = []
    end

    def call
      open_price_file
      validate_headers
      parse_rows
    rescue MissingColumnsError => e
      raise e
    rescue StandardError => e
      raise InvalidFileFormatError, "Could not parse file: #{e.message}"
    end

    private

    def open_workbook
      extension = File.extname(@path).downcase
      @price_file = case extension

      when ".csv"
        Roo::CSV.new(@path)
      when ".xlsx", ".xls"
        Roo::Excelx.new(@path)
      else
        raise InvalidFileFormatError, "Unsupported file format: #{extension}. Please use CSV or Excel file."
      end
    end

    def validate_headers
      header = @price_file.row(1).map(&:to_s).map(&:strip).map(&:downcase)

      @sku_index = header.index("sku")

      # Look for price column with different possible names
      @price_index = header.index("new price") ||

      unless @sku_index && @price_index
        missing = []
        missing << "SKU" unless @sku_index
        missing << "Price" unless @price_index
        raise MissingColumnsError, "Missing required columns: #{missing.join(', ')}. File must contain 'SKU' and 'New Regular Price' columns."
      end
    end

    def parse_rows
      result = []
      invalid_rows = []

      (2..@price_file.last_row).each do |i|
        row = @price_file.row(i)
        sku = row[@sku_index].to_s.strip
        price_value = row[@price_index]

        next if sku.blank?

        begin
          if price < 0
            invalid_rows << { row: i, sku: sku, reason: "Negative price" }
            next
          end

          result << {
            sku: sku,
            new_price: price.to_s
          }
        rescue ArgumentError, TypeError
          invalid_rows << { row: i, sku: sku, reason: "Invalid price format" }
          next
        end
      end

      if invalid_rows.any?
        @errors << "Skipped #{invalid_rows.size} rows with invalid data"
      end

      result
    end
  end
end
