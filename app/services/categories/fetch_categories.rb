module Categories
  class FetchCategories
    def self.call(user, page: 1, per_page: 100)
      new(user, page, per_page).call
    end

    def initialize(user, page, per_page)
      @user = user
      @page = page
      @per_page = per_page
      @client = Woocommerce::CategoriesClient.new(user.store)
    end

    def call
      response = @client.get_categories(per_page: 100)

      raise StandardError, "Failed to fetch categories from WooCommerce" unless response.success?

      raw_categories = response.parsed_response
      categories = raw_categories.map { |cat| Category.from_woocommerce(cat) }

      parent_categories = categories.select { |c| c.parent == 0 }
      categories_by_parent = categories.group_by(&:parent)

      {
        parent_categories: parent_categories,
        categories_by_parent: categories_by_parent
      }
    end
  end
end
