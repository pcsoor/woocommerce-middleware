module Products
  class FetchBySkus
    def self.call(user, skus)
      new(user, skus).call
    end


    def initialize(user, skus)
      @user = user
      @skus = skus
      @client = Woocommerce::ProductsClient.new(user.store)
      @products = []
      @variations = []
    end

    def call
      return [] if @skus.empty?

      fetch_simple_products


      client = Woocommerce::ProductsClient.new(user.store)
      response = client.request(
        :get, "/products",
        query: { sku: skus.join(","), per_page: skus.size }
      )
      raise unless response.success?
    end


    private

    def fetch_simple_products
      response = @client.get_products(sku: @skus.join(","), per_page: @skus.size)
      return unless response.success?

      @products = response
        .parsed_response
        .select { |rawProduct| rawProduct["type"] != "variable" && @skus.include?(rawProduct["sku"]) }
        .map { |rawProduct| Product.from_woocommerce(rawProduct) }

      @found_skus = @products.map(&:sku)
      @remaining_skus = @skus - @found_skus
    end
  end
end
