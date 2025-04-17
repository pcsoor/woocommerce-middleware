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

    def get_products
      Rails.cache.fetch("user:#{@auth[:username]}:products", expires_in: 10.minutes) do
        self.class.get("/products", basic_auth: @auth)
      end
    end

    def get_product(id)
      self.class.get("/products/#{id}", basic_auth: @auth)
    end

    def update_product(id, payload)
      self.class.put(
        "/products/#{id}",
        basic_auth: @auth,
        headers: { "Content-Type" => "application/json" },
        body: payload.to_json
      )
    end

    def get_variations(product_id)
      self.class.get("/products/#{product_id}/variations", basic_auth: @auth)
    end

    def update_variation(product_id, variation_id, payload)
      self.class.put(
        "/products/#{product_id}/variations/#{variation_id}",
        basic_auth: @auth,
        headers: { "Content-Type" => "application/json" },
        body: payload.to_json
      )
    end

    private

    def full_url(endpoint)
      URI.join(@api_url, endpoint).to_s
    end
  end
end
