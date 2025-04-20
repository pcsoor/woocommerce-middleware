class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :init_woocommerce_client

  def index
    categories_data = Categories::FetchCategories.call(current_user)
    @parent_categories = categories_data[:parent_categories]
    @categories_by_parent = categories_data[:categories_by_parent]
  rescue => e
    Rails.logger.error("Categories#index error: #{e.message}")
    redirect_to root_path, alert: "Could not load categories."
  end

  def edit
    @category = Categories::FetchCategory.call(current_user, params[:id])

    categories_data = Categories::FetchCategories.call(current_user)
    @categories = categories_data[:parent_categories] + categories_data[:categories_by_parent].values.flatten
  rescue => e
    Rails.logger.error("Categories#edit error: #{e.message}")
    redirect_to categories_path, alert: "Could not load category."
  end

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

  def category_params
    params.require(:category).permit(:name, :slug, :description, :parent)
  end
end
