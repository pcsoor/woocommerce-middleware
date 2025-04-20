module Categories
  class FetchCategory
    def self.call(user, category_id)
      new(user, category_id).call
    end

    def initialize(user, category_id)
      @user = user
      @category_id = category_id
      @client = Woocommerce::CategoriesClient.new(user.store)
    end

    def call
      response = @client.get_category(@category_id)

      raise StandardError, "Category not found in WooCommerce" unless response.success?

      Category.from_woocommerce(response.parsed_response)
    end
  end
end
