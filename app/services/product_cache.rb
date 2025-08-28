class ProductCache
  # Cache durations based on data volatility
  PRODUCT_TTL = 1.hour
  PRODUCTS_LIST_TTL = 10.minutes
  CATEGORIES_TTL = 1.day
  VARIATIONS_TTL = 30.minutes

  class << self
    def key_for(user_id, product_id)
      "user:#{user_id}:product:#{product_id}"
    end

    def products_list_key(user_id, page, per_page, filters = {})
      filter_hash = filters.empty? ? "" : ":#{filters.to_query}"
      "user:#{user_id}:products:page:#{page}:per:#{per_page}#{filter_hash}"
    end

    # Cache versioning key to invalidate all user cache by incrementing version
    def cache_version_key(user_id)
      "user:#{user_id}:cache_version"
    end

    def categories_key(user_id)
      "user:#{user_id}:categories"
    end

    def variations_key(user_id, product_id)
      "user:#{user_id}:product:#{product_id}:variations"
    end

    def store_data_key(user_id)
      "user:#{user_id}:store_data"
    end

    # Fetch with caching
    def fetch_product(user_id, product_id, ttl: PRODUCT_TTL, &block)
      Rails.cache.fetch(key_for(user_id, product_id), expires_in: ttl, &block)
    end

    def fetch_products_list(user_id, page, per_page, filters = {}, ttl: PRODUCTS_LIST_TTL, &block)
      Rails.cache.fetch(products_list_key(user_id, page, per_page, filters), expires_in: ttl, &block)
    end

    def fetch_categories(user_id, ttl: CATEGORIES_TTL, &block)
      Rails.cache.fetch(categories_key(user_id), expires_in: ttl, &block)
    end

    def fetch_variations(user_id, product_id, ttl: VARIATIONS_TTL, &block)
      Rails.cache.fetch(variations_key(user_id, product_id), expires_in: ttl, &block)
    end

    # Cache invalidation
    def invalidate_product(user_id, product_id)
      Rails.cache.delete(key_for(user_id, product_id))
      invalidate_products_list(user_id) # Product list may contain stale data
      invalidate_variations(user_id, product_id)
    end

    def invalidate_products_list(user_id)
      # Clear common pagination combinations that are likely to be cached
      common_paginations = [
        [1, 25], [2, 25], [3, 25], [4, 25], [5, 25],  # Default 25 per page
        [1, 10], [2, 10], [3, 10], [4, 10], [5, 10],  # 10 per page
        [1, 50], [2, 50], [3, 50]                      # 50 per page
      ]
      
      common_paginations.each do |page, per_page|
        Rails.cache.delete(products_list_key(user_id, page, per_page))
      end
      
      # Also clear any filtered variants (though we don't use filters yet)
      Rails.cache.delete(products_list_key(user_id, 1, 25, {}))
    end

    def invalidate_categories(user_id)
      Rails.cache.delete(categories_key(user_id))
    end

    def invalidate_variations(user_id, product_id)
      Rails.cache.delete(variations_key(user_id, product_id))
    end

    def invalidate_all_user_cache(user_id)
      # Clear all known cache types for this user
      invalidate_products_list(user_id)
      invalidate_categories(user_id)
      Rails.cache.delete(store_data_key(user_id))
      
      Rails.logger.info("Cleared all cached data for user #{user_id}")
    end

    # Alternative: Cache versioning approach (for future use)
    def increment_cache_version(user_id)
      version_key = cache_version_key(user_id)
      current_version = Rails.cache.read(version_key) || 0
      new_version = current_version + 1
      Rails.cache.write(version_key, new_version, expires_in: 1.year)
      Rails.logger.info("Incremented cache version for user #{user_id} to #{new_version}")
      new_version
    end

    def get_cache_version(user_id)
      Rails.cache.read(cache_version_key(user_id)) || 0
    end

    # Batch operations for better performance
    def warm_products_cache(user, products_data)
      products_data.each do |product_data|
        Rails.cache.write(
          key_for(user.id, product_data["id"]), 
          product_data, 
          expires_in: PRODUCT_TTL
        )
      end
    end

    def preload_related_data(user_id, product_ids)
      # Preload variations for variable products in batch
      product_ids.each do |product_id|
        unless Rails.cache.exist?(variations_key(user_id, product_id))
          # This would be called in a background job to warm the cache
          WarmCacheJob.perform_later(user_id, :variations, product_id)
        end
      end
    end
  end
end
