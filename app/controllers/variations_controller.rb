class VariationsController < ApplicationController
  before_action :authenticate_user!
  before_action :init_woocommerce_client

  def edit
    response = @woo_client.get_variation(params[:product_id], params[:id])
    @variation = response.parsed_response
  end

  def update
    payload = {
      regular_price: params[:variation][:regular_price].to_s,
      stock_quantity: params[:variation][:stock_quantity].to_i,
      manage_stock: true
    }

    response = @woo_client.update_variation(params[:product_id], params[:id], payload)

    if response.success?
      redirect_to edit_product_path(params[:product_id]), notice: "Variation updated!"
    else
      flash[:alert] = "Update failed: #{response.parsed_response["message"]}"
      @variation = @woo_client.get_variation(params[:product_id], params[:id]).parsed_response
      render :edit
    end
  end
end
