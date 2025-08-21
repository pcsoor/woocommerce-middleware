class HomeController < ApplicationController
  skip_before_action :ensure_store_connected

  def index
    # Check if user is logged in
    unless user_signed_in?
      redirect_to new_user_session_path
      return
    end

    # Check if user has store configured
    if current_user.store&.established?
      redirect_to products_path
    else
      redirect_to new_onboardings_path, notice: "Please connect your store first."
    end
  end
end
