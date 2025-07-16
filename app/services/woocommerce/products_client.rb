module Woocommerce
  class ProductsClient < BaseClient
    def get_products(page: 1, per_page: 25, ids: nil, sku: nil)
      query = { page: page, per_page: per_page }
      query[:include] = ids.join(",") if ids.present?
      query[:sku] = sku if sku.present?
      request(:get, "/products", query: query)
    end

    def get_product(id)
      request(:get, "/products/#{id}")
    end

    def create_product(payload)
      request(:post, "/products", body: payload.to_json)
    end

    def update_product(id, payload)
      request(:put, "/products/#{id}", body: payload.to_json)
    end

    def get_variations(product_id)
      request(:get, "/products/#{product_id}/variations")
    end

    def cache_key_for(user_id, product_id)
      "user:#{user_id}:product:#{product_id}"
    end
  end
end
