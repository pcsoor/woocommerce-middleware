class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_store_connected
  
  def index
  end

  private

  def ensure_store_connected
    redirect_to new_onboarding_path unless current_user.store.present?
  end
end
