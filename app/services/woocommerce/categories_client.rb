module Woocommerce
  class CategoriesClient < BaseClient
    def get_categories(page: 1, per_page: 100, ids: nil)
      request(:get, "/products/categories", query: { page: page, per_page: per_page })
    end

    def get_category(id)
      request(:get, "/products/categories/#{id}")
    end

    def update_category(id, payload)
      request(:put, "/products/categories/#{id}", body: payload.to_json)
    end

    def cache_key_for(user_id, category_id)
      "user:#{user_id}:category:#{category_id}"
    end
  end
end
