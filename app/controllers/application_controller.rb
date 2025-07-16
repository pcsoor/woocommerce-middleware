class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_locale
  before_action :ensure_store_connected

  def switch_locale
    session[:locale] = params[:locale] if params[:locale].present?
    redirect_back(fallback_location: root_path)
  end

  protected

  def init_woocommerce_client
    store = current_user.store

    @woo_client = Woocommerce::BaseClient.new(store)
  end

  private

  def set_locale
    I18n.locale = session[:locale] || I18n.default_locale
  end

  def ensure_store_connected
    return unless current_user

    unless current_user.store
      redirect_to new_onboardings_path, notice: "Please connect your store first."
    end
  end
end
