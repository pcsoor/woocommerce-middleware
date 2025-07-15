class StoreController < ApplicationController
  before_action :authenticate_user!
  before_action :set_store
  skip_before_action :ensure_store_connected

  def show
  end

  def edit
  end

  def update
    debugger

    if @store.update(store_params)
      if turbo_frame_request?
        # For turbo frame requests, we need to render the partial with the updated data
        render "settings/tabs/store", layout: false
      else
        redirect_to store_path, notice: "Store settings updated successfully!"
      end
    else
      if turbo_frame_request?
        render "settings/tabs/store", layout: false, status: :unprocessable_entity
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def test_connection
    begin
      client = Woocommerce::BaseClient.new(@store)
      response = client.get('products', query: { per_page: 1 })

      if response.success?
        redirect_to store_path, notice: 'Connection successful! Your WooCommerce API is working properly.'
      else
        redirect_to store_path, alert: "Connection failed: #{extract_error_message(response)}"
      end
    rescue => e
      redirect_to store_path, alert: "Connection failed: #{e.message}"
    end
  end

  private

  def set_store
    @store = current_user.store || current_user.build_store
  end

  def store_params
    params.require(:store).permit(:name, :api_url, :consumer_key, :consumer_secret)
  end

  def turbo_frame_request?
    request.headers['Turbo-Frame'].present?
  end

  def extract_error_message(response)
    if response.parsed_response.is_a?(Hash)
      response.parsed_response.dig("message") ||
        response.parsed_response.dig("data", "message") ||
        "HTTP #{response.code}: #{response.message}"
    else
      "HTTP #{response.code}: #{response.message}"
    end
  end
end
