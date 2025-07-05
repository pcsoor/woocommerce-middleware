class HomeController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :ensure_store_connected

  def index; end
end
