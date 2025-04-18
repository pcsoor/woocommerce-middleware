module WooCommerce
  class Client
    include HTTParty
    format :json

    def initialize(api_url, consumer_key, consumer_secret)
      @api_url = api_url.chomp("/") + "/wp-json/wc/v3/"
      @auth = {
        username: consumer_key,
        password: consumer_secret
      }

      self.class.base_uri(@api_url)
    end

    def get_products(page: 1, per_page: 25, ids: nil)
      cache_key = "user:#{@auth[:username]}:products:page:#{page}:per_page:#{per_page}:ids:#{ids&.join(',')}"

      Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
        query = {
          page: page,
          per_page: per_page
        }

        query[:include] = ids.join(",") if ids.present?

        request(:get, "/products", query)
      end
    end

    def get_product(id)
      request(:get, "/products/#{id}")
    end

    def update_product(id, payload)
      request(:put, "/products/#{id}", body: payload.to_json)
    end

    def create_product(payload)
      request(:post, "/products", body: payload.to_json)
    end

    def get_variations(product_id)
      request(:get, "/products/#{product_id}/variations")
    end

    def create_variation(product_id, payload)
      request(:post, "/products/#{product_id}/variations", body: payload.to_json)
    end

    def update_variation(product_id, variation_id, payload)
      request(:put, "/products/#{product_id}/variations/#{variation_id}", body: payload.to_json)
    end

    private

    def full_url(endpoint)
      URI.join(@api_url, endpoint).to_s
    end

    def request(method, endpoint, options = {})
      self.class.send(method, endpoint, {
        basic_auth: @auth,
        headers: { "Content-Type" => "application/json" }
      }.merge(options))
    end
  end
end
