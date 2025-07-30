module Woocommerce
  class BaseClient
    def initialize(store)
      @api_url = store.api_url.chomp("/") + "/wp-json/wc/v3/"
      @store = store
    end

    def get(endpoint, query: {})
      request(:get, endpoint, query: query)
    end

    def post(endpoint, body: {}, query: {})
      request(:post, endpoint, query: query, body: body)
    end

    def put(endpoint, body: {}, query: {})
      request(:put, endpoint, query: query, body: body)
    end

    def delete(endpoint, query: {})
      request(:delete, endpoint, query: query)
    end

    private

    def request(method, endpoint, query: {}, body: nil)
      url = "#{@api_url}#{endpoint.sub(/^\//, '')}"

      request_options = {
        method: method,
        headers: default_headers,
        params: query,
        timeout: 30,
        connecttimeout: 10,
        followlocation: true,
        ssl_verifypeer: Rails.env.production?,
        ssl_verifyhost: Rails.env.production? ? 2 : 0
      }

      if body.present? && [:post, :put].include?(method)
        request_options[:body] = body.is_a?(String) ? body : body.to_json
      end

      Rails.logger.info("WooCommerce API: #{method.upcase} #{url}")

      typhoeus_response = execute_with_retries(url, request_options, endpoint, method)

      Woocommerce::Response.new(typhoeus_response)
    end

    def execute_with_retries(url, options, endpoint, method, max_attempts: 3)
      attempts = 0

      loop do
        attempts += 1
        response = Typhoeus::Request.new(url, options).run

        if response.code == 0
          error_msg = "Network error: #{response.return_message}"
          Rails.logger.error("WooCommerce API error: #{error_msg}")

          if attempts < max_attempts
            Rails.logger.warn("Retrying... (attempt #{attempts}/#{max_attempts})")
            sleep(attempts)
            next
          else
            raise StandardError, "#{error_msg} after #{max_attempts} attempts"
          end
        end

        Rails.logger.info("WooCommerce API response: #{method.upcase} #{endpoint} - Status: #{response.code}")

        if response.code >= 500 && attempts < max_attempts
          Rails.logger.warn("Server error #{response.code}, retrying... (attempt #{attempts}/#{max_attempts})")
          sleep(attempts)
          next
        end

        return response
      end
    end

    def default_headers
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'User-Agent' => 'Mozilla/5.0 (compatible; WooCommerce-Middleware/1.0)',
        'Authorization' => "Basic #{Base64.strict_encode64("#{@store.consumer_key}:#{@store.consumer_secret}")}"
      }
    end
  end
end