module Products
  class UpdateProduct
    Result = Struct.new(:success?, :product, :error)

    def self.call(user, product_id, params)
      new(user, product_id, params).call
    end

    def initialize(user, product_id, params)
      @user = user
      @product_id = product_id
      @params = params
      @client = Woocommerce::ProductsClient.new(user.store)
    end

    def call
      product = Product.new(@params.merge(id: @product_id))

      unless product.valid?
        return Result.new(false, product, "Validation failed.")
      end

      response = @client.update_product(@product_id, product.to_woocommerce_payload)

      if response.success?
        Rails.cache.write(ProductCache.key_for(@user.id, @product_id), response.parsed_response, expires_in: 10.minutes)
        Result.new(true, product, nil)
      else
        Result.new(false, product, "WooCommerce error: #{response.parsed_response["message"]}")
      end
    end
  end
end
