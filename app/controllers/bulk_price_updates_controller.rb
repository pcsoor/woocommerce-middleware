class BulkPriceUpdatesController < ApplicationController
  include BulkPriceUpdateSession
  
  before_action :authenticate_user!
  before_action :cleanup_expired_sessions, only: [:new]
  before_action :require_update_session, only: [:validate, :import, :results]

  def new
  end

  def create
    return render_missing_file_error unless price_file_present?

    result = ProductCsvParser.call(price_file)

    if result.success
      store_update_data(price_file.original_filename, result.products, result.summary)
      redirect_to_validation_with_success_message(result.summary)
    else
      render_parsing_error(result.errors)
    end
  end

  def validate
    @products = build_products_from_session
    @summary = update_data["summary"]
    @timestamp = update_data["timestamp"]

    categorize_products
  end

  def import
    valid_products = build_valid_products_from_session
    result = Products::ProcessPriceUpdates.call(current_user, valid_products)
    
    store_results(result)
    redirect_to results_bulk_price_updates_path, notice: t('bulk_price_updates.processing_completed')
  rescue StandardError => e
    handle_import_error(e)
  end

  def results
    @results = results_data
    @summary = update_data["summary"] if update_data

    redirect_to_new_unless_results_exist
    clear_session_data
  end

  private

  def price_file
    params[:price_file]
  end

  def price_file_present?
    price_file.present?
  end

  def render_missing_file_error
    flash.now[:alert] = t('bulk_price_updates.file_not_selected')
    render :new
  end

  def redirect_to_validation_with_success_message(summary)
    flash[:notice] = t('bulk_price_updates.successfully_parsed', count: summary[:total_rows], filename: summary[:filename])
    redirect_to validate_bulk_price_updates_path
  end

  def render_parsing_error(errors)
    flash.now[:alert] = "#{t('bulk_price_updates.parsing_error')}: #{errors.join(', ')}"
    render :new
  end

  def build_products_from_session
    update_data["products"].map { |data| Product.new(data) }
  end

  def build_valid_products_from_session
    update_data["products"]
      .map { |data| Product.new(data) }
      .select(&:valid?)
  end

  def categorize_products
    add_warnings_to_products
    
    @valid_products = @products.select(&:valid?)
    @invalid_products = @products.reject(&:valid?)
    @products_with_warnings = @valid_products.select(&:has_warnings?)
    @existing_products, @new_products = @valid_products.partition { |product| product_exists?(product.sku) }
  end

  def add_warnings_to_products
    @products.each { |product| ProductWarningService.call(product, current_user) }
  end

  def product_exists?(sku)
    WoocommerceSkuChecker.call(sku, current_user.store)
  end

  def handle_import_error(error)
    Rails.logger.error("Bulk price update processing error: #{error.message}")
    flash[:alert] = "#{t('bulk_price_updates.error_processing')}: #{error.message}"
    redirect_to validate_bulk_price_updates_path
  end

  def redirect_to_new_unless_results_exist
    return if @results

    flash[:alert] = t('bulk_price_updates.no_results_found')
    redirect_to new_bulk_price_update_path
  end
end
