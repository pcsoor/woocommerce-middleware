class OnboardingsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :ensure_store_connected

  def new
    @store = Store.new
  end

  def create
    @store = current_user.build_store(store_params)

    # Set a default name if not provided
    @store.name = "My WooCommerce Store" if @store.name.blank?

    unless @store.valid?
      error_message = @store.errors.full_messages.join(', ')
      Rails.logger.error("Store validation failed: #{error_message}")
      return render_new("Please fix the following errors: #{error_message}")
    end

    unless valid_woocommerce_credentials?
      Rails.logger.error("WooCommerce API validation failed for URL: #{@store.api_url}")
      return render_new("Could not connect to WooCommerce. Please check your API URL and credentials.")
    end

    if @store.save
      redirect_to products_path, notice: "Store connected successfully."
    else
      error_message = @store.errors.full_messages.join(', ')
      Rails.logger.error("Store save failed: #{error_message}")
      render_new("Failed to save store: #{error_message}")
    end
  end

  private

  def store_params
    params.require(:store).permit(:name, :api_url, :consumer_key, :consumer_secret)
  end

  def render_new(message)
    flash.now[:alert] = message
    render :new
  end

  def valid_woocommerce_credentials?
    client = Woocommerce::BaseClient.new(@store)

    begin
      # Try a simple API call to verify credentials
      response = client.get("products", query: { per_page: 1 })
      
      if response.success?
        Rails.logger.info("WooCommerce API validation successful")
        return true
      else
        Rails.logger.error("WooCommerce API returned #{response.code}: #{response.message}")
        return false
      end
    rescue => e
      Rails.logger.error("WooCommerce auth failed: #{e.class} - #{e.message}")
      return false
    end
  end
end
