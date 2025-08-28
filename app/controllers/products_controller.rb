class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :init_woocommerce_client

  def index
    page = params.fetch(:page, 1)
    per_page = params.fetch(:per_page, 25)

    @products = Products::FetchProducts.call(current_user, page: page, per_page: per_page)
  rescue => e
    Rails.logger.error("Products#index error: #{e.message}")
    redirect_to settings_path, alert: t("products.alerts.store_connection_error")
  end

  def edit
    @product = Products::FetchProduct.call(current_user, params[:id])

    load_variations if @product.type == "variable"
  rescue => e
    Rails.logger.error("Products#edit error: #{e.message}")
    redirect_to products_path, alert: t("products.alerts.could_not_load")
  end

  def update
    result = Products::UpdateProduct.call(current_user, params[:id], product_params)

    if result.success?
      # Invalidate relevant caches
      ProductCache.invalidate_product(current_user.id, params[:id])
      
      redirect_to products_path, notice: t('products.alerts.update_success')
    else
      @product = result.product
      flash[:alert] = result.error
      render :edit
    end
  end

  private

  def product_params
    permitted = params.require(:product).permit(
      :name,
      :regular_price,
      :sale_price,
      :stock_quantity,
      :manage_stock,
      :sku,
      :type,
      :status,
      :featured,
      :short_description,
      :description,
      :weight,
      :downloadable,
      :virtual,
      categories: [],
      tags: [],
      images: [],
      dimensions: [ :length, :width, :height ],
      meta_data: {}
    )

    # Sanitize and validate inputs
    sanitize_product_params(permitted)
  end

  def sanitize_product_params(params)
    # Sanitize text fields
    params[:name] = sanitize_text(params[:name])
    params[:sku] = sanitize_sku(params[:sku])
    params[:description] = sanitize_html(params[:description])
    params[:short_description] = sanitize_html(params[:short_description])

    # Validate and sanitize numeric fields
    params[:regular_price] = sanitize_price(params[:regular_price])
    params[:sale_price] = sanitize_price(params[:sale_price])
    params[:stock_quantity] = sanitize_integer(params[:stock_quantity])
    params[:weight] = sanitize_decimal(params[:weight])

    # Validate enum fields
    params[:status] = sanitize_status(params[:status])
    params[:type] = sanitize_product_type(params[:type])

    params
  end

  def sanitize_text(value)
    return nil if value.blank?
    value.to_s.strip.truncate(255)
  end

  def sanitize_sku(value)
    return nil if value.blank?
    # SKU should only contain alphanumeric, hyphens, and underscores
    value.to_s.strip.gsub(/[^a-zA-Z0-9\-_]/, '').truncate(100)
  end

  def sanitize_html(value)
    return nil if value.blank?
    # Basic HTML sanitization - remove script tags and limit allowed tags
    ActionController::Base.helpers.sanitize(value, tags: %w[p br strong em ul ol li])
  end

  def sanitize_price(value)
    return nil if value.blank?
    price = value.to_f
    price >= 0 ? price : nil
  end

  def sanitize_integer(value)
    return nil if value.blank?
    int_val = value.to_i
    int_val >= 0 ? int_val : nil
  end

  def sanitize_decimal(value)
    return nil if value.blank?
    decimal_val = value.to_f
    decimal_val >= 0 ? decimal_val : nil
  end

  def sanitize_status(value)
    valid_statuses = %w[draft pending private publish]
    valid_statuses.include?(value) ? value : 'draft'
  end

  def sanitize_product_type(value)
    valid_types = %w[simple grouped external variable]
    valid_types.include?(value) ? value : 'simple'
  end

  def load_variations
    begin
      @variations = ProductCache.fetch_variations(current_user.id, @product.id) do
        response = Woocommerce::ProductsClient.new(current_user.store).get_variations(@product.id)

        if response.success?
          response.parsed_response
        else
          error_message = response.parsed_response.is_a?(Hash) ? 
            response.parsed_response["message"] : 
            "HTTP #{response.code}"
          Rails.logger.error("Failed to load variations for product #{@product.id}: #{error_message}")
          []
        end
      end
    rescue => e
      @variations = []
      Rails.logger.error("Load variations error: #{e.message}")
      flash.now[:alert] = "Could not load variations due to an error."
    end

    if @variations.empty? && !flash.now[:alert]
      flash.now[:alert] = "Could not load variations for this product."
    end
  end

  def product_cache_key(product_id)
    "user:#{current_user.id}:product:#{product_id}"
  end
end
