class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :init_woocommerce_client

  def index
    page = params.fetch(:page, 1)
    per_page = params.fetch(:per_page, 25)

    @products = Products::FetchProducts.call(current_user, page: page, per_page: per_page)
  rescue => e
    Rails.logger.error("Products#index error: #{e.message}")
    redirect_to root_path, alert: "Could not load products."
  end

  def edit
    @product = Products::FetchProduct.call(current_user, params[:id])

    load_variations if @product.type == "variable"
  rescue => e
    Rails.logger.error("Products#edit error: #{e.message}")
    redirect_to products_path, alert: "Could not load product."
  end

  def update
    result = Products::UpdateProduct.call(current_user, params[:id], product_params)

    if result.success?
      redirect_to products_path, notice: "Product updated successfully."
    else
      @product = result.product
      flash[:alert] = result.error
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
    response = Woocommerce::ProductsClient.new(current_user.store).get_variations(@product.id)

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
