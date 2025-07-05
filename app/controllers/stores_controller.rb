class StoresController < ApplicationController
  before_action :authenticate_user!
  before_action :set_store

  def show
  end

  def edit
  end

  def update
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
    params.require(:store).permit(:api_url, :consumer_key, :consumer_secret)
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
