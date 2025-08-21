require 'ostruct'

class ProductCsvParser
  def self.call(file)
    new(file).call
  end

  def initialize(file)
    @processor = CsvFileProcessor.new(file: file)
  end

  def call
    return OpenStruct.new(success: false, errors: @processor.errors.full_messages) unless @processor.valid?

    products = @processor.process { |row, _| build_product_from_row(row) }
    
    OpenStruct.new(
      success: true,
      products: products,
      summary: @processor.summary
    )
  rescue StandardError => e
    Rails.logger.error "Product CSV parsing error: #{e.message}"
    OpenStruct.new(success: false, errors: [e.message])
  end

  private

  def build_product_from_row(row)
    # Debug: Log the raw row data
    Rails.logger.debug "Processing CSV row: #{row.to_h.inspect}"
    
    sku = sanitize_text(row["SKU"])
    name = sanitize_text(row["Name"] || row["Név"])
    regular_price = parse_price(row["Regular Price"] || row["Price"] || row["Ár"])
    
    # Debug: Log the parsed values
    Rails.logger.debug "Parsed values - SKU: #{sku.inspect}, Name: #{name.inspect}, Price: #{regular_price.inspect}"
    
    product = Product.new(
      sku: sku,
      name: name,
      regular_price: regular_price
    )
    
    # Debug: Log validation errors if any
    unless product.valid?
      Rails.logger.debug "Product validation errors: #{product.errors.full_messages.join(', ')}"
    end
    
    product
  end

  def sanitize_text(value)
    value&.to_s&.strip&.presence
  end

  def parse_price(value)
    return nil if value.blank?
    
    # Remove currency symbols and keep only digits and decimal point
    cleaned = value.to_s.gsub(/[^\d.]/, '')
    cleaned.present? ? cleaned.to_f : nil
  end
end 