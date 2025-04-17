class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_store_connected
  before_action :init_woocommerce_client

  def index
    response = @woo_client.get_products

    if response.success?
      @products = response.parsed_response
    else
      render json: { error: "WooCommerce API error" }, status: :bad_gateway
    end
  end

  def edit
    response = @woo_client.get_product(params[:id])

    if response.success?
      product_data = response.parsed_response
      @product = Product.from_woocommerce(product_data)

      load_variations if @product.type == "variable"
    else
      redirect_to products_path, alert: "Product not found"
    end
  end

  def update
    @product = Product.new(product_params.merge(id: params[:id]))

    if @product.valid?
      Rails.logger.debug "Updating WooCommerce product ##{@product.id}"
      Rails.logger.debug "Payload: #{@product.to_woocommerce_payload.inspect}"

      response = @woo_client.update_product(@product.id, @product.to_woocommerce_payload)

      Rails.logger.debug "WooCommerce response: #{response.parsed_response.inspect}"

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

  def ensure_store_connected
    unless current_user.store
      redirect_to onboarding_path, notice: "Please connect your store first."
    end
  end

  def init_woocommerce_client
    store = current_user.store

    @woo_client = WooCommerce::Client.new(
      store.api_url,
      store.consumer_key,
      store.consumer_secret
    )
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
end
