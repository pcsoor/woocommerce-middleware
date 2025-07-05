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
      response = @client.get_products(page: @page, per_page: @per_page)

      unless response.success?
        puts response.
        raise StandardError, "Failed to fetch products from WooCommerce"
      end

      raw_products = response.parsed_response

      raw_products.each do |product_data|
        Rails.cache.write(
          @client.cache_key_for(@user.id, product_data["id"]),
          product_data,
          expires_in: 10.minutes
        )
      end

      products = raw_products.map { |data| Product.from_woocommerce(data) }
      total_products = response.headers["x-wp-total"].to_i

      Kaminari.paginate_array(products, total_count: total_products)
        .page(@page)
        .per(@per_page)
    end
  end
end
