class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :init_woocommerce_client

  def index
    page = params.fetch(:page, 1)
    per_page = params.fetch(:per_page, 25)

    response = @woo_client.get_products(page: page, per_page: per_page)
    return redirect_to(root_path, alert: "You must be logged in to see products.") unless response.success?

    raw_products = response.parsed_response

    raw_products.each do |product_data|
      Rails.cache.write(ProductCache.key_for(current_user.id, product_data["id"]), product_data, expires_in: 10.minutes)
    end

    products = raw_products.map { |data| Product.from_woocommerce(data) }

    total_products = response.headers["x-wp-total"].to_i

    @products = Kaminari.paginate_array(products, total_count: total_products)
      .page(page)
      .per(per_page)

    @current_page = page
  end

  def edit
    product_id = params[:id]

    product_data = Rails.cache.read(ProductCache.key_for(current_user.id, product_id))

    unless product_data
      response = @woo_client.get_product(product_id)

      if response.success?
        product_data = response.parsed_response
        Rails.cache.write(
          ProductCache.key_for(current_user.id, product_id),
          product_data,
          expires_in: 10.minutes
        )
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
    params.require(:product).permit(
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
