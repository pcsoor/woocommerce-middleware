class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :init_woocommerce_client
  before_action :set_category_and_parents, only: [ :edit, :update ]

  def index
    response = @woo_client.get_categories(per_page: 100)

    unless response.success?
      redirect_to root_path, alert: "Failed to fetch categories"
      return
    end

    raw_categories = response.parsed_response
    categories = raw_categories.map { |cat| Category.from_woocommerce(cat) }

    @parent_categories = categories.select { |c| c.parent == 0 }
    @categories_by_parent = categories.group_by(&:parent)
  end

  def edit;  end

  def update
    @category.assign_attributes(category_params)

    if @category.valid?
      response = @woo_client.update_category(@category.id, @category.to_woocommerce_payload)

      if response.success?
        redirect_to categories_path, notice: "Category updated successfully."
      else
        flash[:alert] = "WooCommerce error: #{response.parsed_response["message"]}"
        render :edit
      end
    else
      flash[:alert] = "Validation failed."
      render :edit
    end
  end

  private

  def set_category_and_parents
    response = @woo_client.get_category(params[:id])

    unless response.success?
      redirect_to categories_path, alert: "Category not found"
      return
    end

    @category = Category.from_woocommerce(response.parsed_response)

    categories_response = @woo_client.get_categories(per_page: 100)
    if categories_response.success?
      raw_categories = categories_response.parsed_response
      @categories = raw_categories.map { |cat| Category.from_woocommerce(cat) }
    else
      @categories = []
    end
  end

  def category_params
    params.require(:category).permit(:name, :slug, :description, :parent)
  end
end
