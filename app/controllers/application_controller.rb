class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :ensure_store_connected

  protected

  def init_woocommerce_client
    store = current_user.store

    @woo_client = Woocommerce::BaseClient.new(store)
  end

  private

  def ensure_store_connected
    return unless current_user

    unless current_user.store
      redirect_to new_onboardings_path, notice: "Please connect your store first."
    end
  end
end
