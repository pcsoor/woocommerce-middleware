module Products
  class FetchProducts
    def self.call(user, page: 1, per_page: 25)
      new(user, page, per_page).call
    end

    def initialize(user, page, per_page)
      @user = user
      @page = page
      @per_page = per_page
      @client = Woocommerce::ProductsClient.new(user.store)
    end

    def call
      # Try to fetch from cache first
      result = ProductCache.fetch_products_list(@user.id, @page, @per_page) do
        fetch_from_api
      end

      result
    end

    private

    def fetch_from_api
      response = @client.get_products(page: @page, per_page: @per_page)

      unless response.success?
        Rails.logger.error("Failed to fetch products from WooCommerce: #{response.code} - #{response.message}")
        raise StandardError, "Failed to fetch products from WooCommerce"
      end

      raw_products = response.parsed_response
      total_products = response.headers["x-wp-total"].to_i

      # Warm individual product caches for better performance
      ProductCache.warm_products_cache(@user, raw_products)

      products = raw_products.map { |data| Product.from_woocommerce(data) }

      Kaminari.paginate_array(products, total_count: total_products)
        .page(@page)
        .per(@per_page)
    end
  end
end
