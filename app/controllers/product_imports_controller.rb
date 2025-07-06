class ProductImportsController < ApplicationController
  def new
    session[:import_data] = nil
  end

  def create
    if params[:csv_file].present?
      begin
        parser = CsvParser.new(params[:csv_file])
        products = parser.parse

        session[:import_data] = {
          "products": products.map(&:attributes),
          "summary": parser.summary,
          "timestamp": Time.current
        }

        flash[:notice] = "Successfully parsed #{parser.summary[:total_rows]} products from #{parser.summary[:filename]}"
        redirect_to validate_product_imports_path
      rescue => e
        flash[:alert] = "Error parsing file: #{e.message}"
        redirect_to new_product_import_path
      end
    else
      flash[:alert] = "Please select a CSV file"
      redirect_to new_product_import_path
    end

  end

  def validate
    redirect_and_return_if_no_session_data

    products_data = session[:import_data]["products"]
    @products = products_data.map { |data| Product.new(data) }
    @summary = session[:import_data]["summary"]

    @products.each { |product| add_import_warnings(product) }

    @valid_products = @products.select(&:valid?)
    @invalid_products = @products.reject(&:valid?)
    @products_with_warnings = @products.select { |p| p.valid? && p.has_warnings? }
  end

  private

  def redirect_and_return_if_no_session_data
    unless session[:import_data]&.dig("products")
      flash[:alert] = "Import session expired. Please upload your file again."
      redirect_to new_product_import_path
      return true
    end

    false
  end

  def add_import_warnings(product)
    return unless product.valid?

    product.add_warning("No name provided") if product.name.blank?
    product.add_warning("No regular price provided") if product.regular_price.blank?

    if sku_exists_in_woocommerce?(product.sku)
      product.add_warning("SKU already exists in WooCommerce")
    end
  end

  def sku_exists_in_woocommerce?(sku)
    false
  end
end
