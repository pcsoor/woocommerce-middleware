class ProductImportsController < ApplicationController
  def new
    session[:import_data] = nil
  end
end
