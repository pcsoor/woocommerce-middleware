class BulkPriceUpdatesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_product

  def new
  end

  def create
    if params[:price_file].blank?
      flash[:alert] = "Please select a file to upload."
      render :new
    end


    begin
      file = params.require(:price_file)
      @rows = Products::
    rescue StandardError => e
      flash[:alert] = "Error processing file: #{e.message}"
      render :new
    end
  end
end
