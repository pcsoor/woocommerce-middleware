class OnboardingsController < ApplicationController
  before_action :authenticate_user!, only: [ :create ]
  skip_before_action :ensure_store_connected, only: [ :new ]

  def new
    @store = Store.new
  end

  def create
    @store = current_user.build_store(store_params)
    if valid_woocommerce_credentials?(@store)
      if @store.save
        redirect_to products_path, notice: "Store connected successfully."
      else
        flash.now[:alert] = "Failed to save store configuration."
        render :new
      end
    else
      flash.now[:alert] = "Invalid WooCommerce API credentials."
      render :new
    end
  end

  private

  def store_params
    params.require(:store).permit(:api_url, :consumer_key, :consumer_secret)
  end

  def valid_woocommerce_credentials?(store)
    client = WooCommerce::Client.new(
      store.api_url,
      store.consumer_key,
      store.consumer_secret
    )

    begin
      response = client.get("products", per_page: 1)
      response.code == 200
    rescue StandardError => e
      Rails.logger.error("WooCommerce auth failed: #{e.message}")
      false
    end
  end
end
