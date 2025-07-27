module Woocommerce
  class BaseClient
    include HTTParty
    format :json
    
    # Default timeout and retry configuration
    default_timeout 30
    default_options.update(
      verify: Rails.env.production?,
      timeout: 30,
      open_timeout: 10
    )

    def initialize(store)
      @api_url = store.api_url.chomp("/") + "/wp-json/wc/v3/"
      @auth = {
        username: store.consumer_key,
        password: store.consumer_secret
      }
      @store = store
      
      # Use instance-level base_uri to avoid thread safety issues
      @base_uri = @api_url
    end

    def get(endpoint, query: {})
      request(:get, endpoint, query: query)
    end

    def post(endpoint, body: {}, query: {})
      request(:post, endpoint, query: query, body: body.to_json)
    end

    def put(endpoint, body: {}, query: {})
      request(:put, endpoint, query: query, body: body.to_json)
    end

    def delete(endpoint, query: {})
      request(:delete, endpoint, query: query)
    end

    private

    def request(method, endpoint, query: {}, body: nil)
      attempts ||= 3
      
      begin
        url = "#{@base_uri}#{endpoint.sub(/^\//, '')}"
        
        # More flexible timeout settings for production
        timeout = Rails.env.production? ? 60 : 30
        open_timeout = Rails.env.production? ? 20 : 10
        
        options = {
          basic_auth: @auth,
          headers: { 
            "Content-Type" => "application/json",
            "User-Agent" => "WooCommerce-Middleware/1.0"
          },
          query: query,
          timeout: timeout,
          open_timeout: open_timeout,
          verify: true  # Always verify SSL certificates
        }
        
        options[:body] = body if body.present?

        Rails.logger.info("WooCommerce API #{method.upcase} #{url} (attempt #{4-attempts}/3)")
        
        response = HTTParty.send(method, url, options)

        Rails.logger.info("WooCommerce API #{method.upcase} #{endpoint}: #{response.code}")
        Rails.logger.debug("Response: #{response.parsed_response}") if Rails.env.development?

        response
      rescue Net::ReadTimeout, Net::OpenTimeout => e
        Rails.logger.warn("WooCommerce API timeout (attempt #{4-attempts}/3): #{e.message}")
        attempts -= 1
        if attempts > 0
          sleep(1) # Longer pause for production timeouts
          retry
        end
        raise StandardError, "API request timed out after 3 attempts: #{e.message}"
      rescue Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
        Rails.logger.warn("WooCommerce API connection error (attempt #{4-attempts}/3): #{e.message}")
        attempts -= 1
        if attempts > 0
          sleep(2) # Longer pause for connection issues
          retry
        end
        raise StandardError, "Network error connecting to WooCommerce: #{e.message}"
      rescue => e
        Rails.logger.error("WooCommerce API unexpected error: #{e.class} - #{e.message}")
        Rails.logger.error("URL: #{url}")
        Rails.logger.error("Store: #{@store.api_url}")
        raise StandardError, "API request failed: #{e.message}"
      end
    end
  end
end
