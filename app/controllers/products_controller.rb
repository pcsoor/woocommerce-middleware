class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :init_woocommerce_client

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 25

    response = @woo_client.get_products(page: page, per_page: per_page)

    if response.success?
      @products = response.parsed_response
      @products.each do |product_data|
        Rails.cache.write(product_cache_key(product_data["id"]), product_data, expires_in: 10.minutes)
      end
    else
      render json: { error: "WooCommerce API error" }, status: :bad_gateway
    end
  end

  def edit
    product_data = Rails.cache.read(product_cache_key(params[:id]))

    unless product_data
      response = @woo_client.get_product(params[:id])
      if response.success?
        product_data = response.parsed_response
        Rails.cache.write(product_cache_key(product_data["id"]), product_data, expires_in: 10.minutes)
      else
        redirect_to products_path, alert: "Product not found"
        return
      end
    end

    @product = Product.from_woocommerce(product_data)
    load_variations if @product.type == "variable"
  end

  def update
    @product = Product.new(product_params.merge(id: params[:id]))

    if @product.valid?
      response = @woo_client.update_product(@product.id, @product.to_woocommerce_payload)

      if response.success?
        redirect_to products_path, notice: "Product updated successfully."
      else
        flash[:alert] = "WooCommerce error: #{response.parsed_response["message"]}"
        render :edit
      end
    else
      flash[:alert] = "Validation failed. Please check the form."
      render :edit
    end
  end

  private

  def product_params
    params.require(:product).permit(:name, :regular_price, :type, :manage_stock, :stock_quantity)
  end

  def load_variations
    response = @woo_client.get_variations(@product.id)

    if response.success?
      @variations = response.parsed_response
    else
      @variations = []
      flash.now[:alert] = "Could not load variations: #{response.parsed_response["message"]}"
    end
  end

  def product_cache_key(product_id)
    "user:#{current_user.id}:product:#{product_id}"
  end
end
