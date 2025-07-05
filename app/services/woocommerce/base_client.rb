module Woocommerce
  class BaseClient
    include HTTParty
    format :json

    def initialize(store)
      @api_url = store.api_url.chomp("/") + "/wp-json/wc/v3/"
      @auth = {
        username: store.consumer_key,
        password: store.consumer_secret
      }
      self.class.base_uri(@api_url)
    end

    def get(endpoint, query: {})
      request(:get, endpoint, query: query)
    end

    private

    def request(method, endpoint, query: {}, body: nil)
      begin
        attempts ||= 3
        response = self.class.send(method, endpoint, {
          basic_auth: @auth,
          headers: { "Content-Type" => "application/json" },
          query: query,
          body: body,
          verify: false
        })

        Rails.logger.info("WooCommerce API Response: #{response.code} - #{response.message}")

        response
      rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED => e
        Rails.logger.error("WooCommerce API network error: #{e.message}")
        attempts -= 1
        retry if attempts > 0
        raise StandardError, "Network error connecting to WooCommerce: #{e.message}"
      rescue => e
        Rails.logger.error("WooCommerce API unexpected error: #{e.class} - #{e.message}")
        raise StandardError, "API request failed: #{e.message}"
      end
    end
  end
end
