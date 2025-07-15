class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_active_tab
  before_action :set_user_and_store, only: [:show]

  def show
    redirect_to settings_path(tab: "profile") and return if params[:tab].blank?

    if turbo_frame_request?
      render "tabs/#{@active_tab}", layout: false
    else
      render :show
    end
  end

  private

  def set_active_tab
    @active_tab = params[:tab] || "profile"
  end

  def set_user_and_store
    @user = current_user
    @store = current_user.store || current_user.build_store
  end

  def turbo_frame_request?
    request.headers['Turbo-Frame'].present?
  end
end