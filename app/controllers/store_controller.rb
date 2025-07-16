class StoreController < ApplicationController
  before_action :authenticate_user!
  before_action :set_store
  skip_before_action :ensure_store_connected

  def show
  end

  def edit
  end

  def update
    Rails.logger.debug "=== STORE UPDATE DEBUG ==="
    Rails.logger.debug "Turbo-Frame header: #{request.headers['Turbo-Frame']}"
    Rails.logger.debug "Accept header: #{request.headers['Accept']}"
    Rails.logger.debug "Is turbo frame request? #{turbo_frame_request?}"
    Rails.logger.debug "=============================="
    
    if @store.update(store_params)
      if turbo_frame_request?
        # For turbo frame requests, render the store tab partial to stay in settings
        flash.now[:notice] = "Store settings updated successfully!"
        render "settings/tabs/_store", layout: false
      else
        redirect_to store_path, notice: "Store settings updated successfully!"
      end
    else
      if turbo_frame_request?
        render "settings/tabs/_store", layout: false, status: :unprocessable_entity
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
        success_message = 'Connection successful! Your WooCommerce API is working properly.'
        if turbo_frame_request?
          flash.now[:notice] = success_message
          render "settings/tabs/_store", layout: false
        else
          redirect_to store_path, notice: success_message
        end
      else
        error_message = "Connection failed: #{extract_error_message(response)}"
        if turbo_frame_request?
          flash.now[:alert] = error_message
          render "settings/tabs/_store", layout: false
        else
          redirect_to store_path, alert: error_message
        end
      end
    rescue => e
      error_message = "Connection failed: #{e.message}"
      if turbo_frame_request?
        flash.now[:alert] = error_message
        render "settings/tabs/_store", layout: false
      else
        redirect_to store_path, alert: error_message
      end
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
