class MergeSimpleProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :init_woocommerce_client
  before_action :load_products, only: [ :new, :create ]

  def new; end

  def create
    attribute_name = params[:attribute_name]
    parent_product_name = params[:parent_product_name]

    if attribute_name.blank? || parent_product_name.blank?
      flash.now[:alert] = "Attribute name and parent product name are required."
      render :new
      return
    end

    selected_product_ids = @products.map { |p| p["id"] }

    # Queue the background job
    MergeSimpleProductsJob.perform_later(
      current_user.store.id,
      selected_product_ids,
      attribute_name,
      parent_product_name
    )

    redirect_to products_path, notice: "Merge started! We'll notify you when it's ready."
  end

  private

  def load_products
    product_ids = params[:product_ids]

    Rails.logger.debug("Cheese 2: #{product_ids}")

    response = @woo_client.get_products(ids: product_ids)

    if response.success?
      @products = response.parsed_response
      @products = @products.select { |p| product_ids.include?(p["id"].to_s) }
    else
      @products = []
      flash[:alert] = "Failed to load selected products from WooCommerce."
      redirect_to products_path
    end
  rescue StandardError => e
    flash[:error] = "Failed to fetch products for merging"
    Rails.logger.error("Failed to fetch products for merging: #{e.message}")
    redirect_to products_path
  end
end
