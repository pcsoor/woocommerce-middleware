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
      fetch_variations_if_needed

      @products
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

    def fetch_variations_if_needed
      return if @remaining_skus.empty?

      # For remaining SKUs, check if they are variations of variable products
      response = @client.get_products(type: 'variable', per_page: 100)
      return unless response.success?

      variable_products = response.parsed_response
      
      variable_products.each do |variable_product|
        variations_response = @client.get_variations(variable_product['id'])
        next unless variations_response.success?

        matching_variations = variations_response.parsed_response.select do |variation|
          @remaining_skus.include?(variation['sku'])
        end

        matching_variations.each do |variation_data|
          @variations << Product.from_woocommerce(variation_data)
        end
      end

      @products += @variations
    end
  end
end
