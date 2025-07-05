class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  skip_before_action :ensure_store_connected

  def show
    # Profile view
  end

  def edit
    # Edit profile form
  end

  def update
    if @user.update(user_params)
      redirect_to user_path, notice: 'Profile updated successfully.'
    else
      render :edit
    end
  end

  def profile; end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
