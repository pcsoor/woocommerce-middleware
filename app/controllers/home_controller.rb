class HomeController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :ensure_store_connected

  def index
    @store_connected = current_user.store&.established?
    
    if @store_connected
      begin
        # Fetch a small sample of products for recent activity
        @recent_products = Products::FetchProducts.call(current_user, page: 1, per_page: 5)
        
        # Get total product count from API response headers
        @product_count = @recent_products.total_count if @recent_products.respond_to?(:total_count)
        
        # Fetch categories to get count
        categories_data = Categories::FetchCategories.call(current_user)
        @category_count = categories_data[:parent_categories].length + categories_data[:categories_by_parent].values.flatten.length
      rescue => e
        Rails.logger.error("Home#index API error: #{e.message}")
        @recent_products = []
        @product_count = 0
        @category_count = 0
      end
    else
      @recent_products = []
      @product_count = 0
      @category_count = 0
    end
  end
end
