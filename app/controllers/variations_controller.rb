class VariationsController < ApplicationController
  before_action :authenticate_user!
  before_action :init_woocommerce_client

  def edit
    response = @woo_client.get_variation(params[:product_id], params[:id])
    
    if response.success?
      @variation = response.parsed_response
    else
      Rails.logger.error("Failed to fetch variation: #{response.parsed_response['message']}")
      redirect_to edit_product_path(params[:product_id]), alert: "Could not load variation."
    end
  rescue => e
    Rails.logger.error("Variation#edit error: #{e.message}")
    redirect_to edit_product_path(params[:product_id]), alert: "Could not load variation."
  end

  def update
    payload = {
      regular_price: params[:variation][:regular_price].to_s,
      stock_quantity: params[:variation][:stock_quantity].to_i,
      manage_stock: true
    }

    response = @woo_client.update_variation(params[:product_id], params[:id], payload)

    if response.success?
      # Invalidate related caches
      ProductCache.invalidate_variations(current_user.id, params[:product_id])
      ProductCache.invalidate_product(current_user.id, params[:product_id])
      
      redirect_to edit_product_path(params[:product_id]), notice: "Variation updated!"
    else
      error_message = response.parsed_response.is_a?(Hash) ? 
        response.parsed_response["message"] : 
        "HTTP #{response.code}"
      flash[:alert] = "Update failed: #{error_message}"
      
      # Try to reload variation data
      variation_response = @woo_client.get_variation(params[:product_id], params[:id])
      @variation = variation_response.success? ? variation_response.parsed_response : {}
      render :edit
    end
  end
end
