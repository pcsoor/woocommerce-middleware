class OnboardingsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :ensure_store_connected

  def new
    @store = Store.new
  end

  def create
    @store = current_user.build_store(store_params)

    return render_new("Failed to save store configuration.") unless @store.valid?
    return render_new("Invalid WooCommerce API credentials.") unless valid_woocommerce_credentials?

    if @store.save
      redirect_to products_path, notice: "Store connected successfully."
    else
      render_new("Failed to save store configuration.")
    end
  end

  private

  def store_params
    params.require(:store).permit(:api_url, :consumer_key, :consumer_secret)
  end

  def render_new(message)
    flash.now[:alert] = message
    render :new
  end

  def valid_woocommerce_credentials?
    client = Woocommerce::BaseClient.new(@store)

    begin
      response = client.get("")
      response.code == 200
    rescue StandardError => e
      Rails.logger.error("WooCommerce auth failed: #{e.message}")
      false
    end
  end
end
