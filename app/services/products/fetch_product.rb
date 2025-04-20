module Products
  class FetchProduct
    def self.call(user, product_id)
      new(user, product_id).call
    end

    def initialize(user, product_id)
      @user = user
      @product_id = product_id
      @client = Woocommerce::ProductsClient.new(user.store)
    end

    def call
      product_data = Rails.cache.fetch(ProductCache.key_for(@user.id, @product_id), expires_in: 10.minutes) do
        response = @client.get_product(@product_id)
        raise StandardError, "Product not found in WooCommerce" unless response.success?

        response.parsed_response
      end

      Product.from_woocommerce(product_data)
    end
  end
end
