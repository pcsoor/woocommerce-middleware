module BulkPriceUpdateSession
  extend ActiveSupport::Concern

  SESSION_KEY = :price_update_data
  RESULTS_KEY = :price_update_results
  SESSION_TIMEOUT = 1.hour

  private

  def store_update_data(filename, products, summary)
    session[SESSION_KEY] = {
      filename: filename,
      timestamp: Time.current.to_s,
      products: products.map(&:attributes),
      summary: summary
    }
  end

  def store_results(result)
    session[RESULTS_KEY] = {
      success: result.success?,
      updated_count: result.updated_count,
      created_count: result.created_count,
      failed_count: result.failed_count,
      errors: result.errors,
      timestamp: Time.current.to_s
    }
  end

  def clear_session_data
    session.delete(SESSION_KEY)
    session.delete(RESULTS_KEY)
  end

  def update_data
    @update_data ||= session[SESSION_KEY]
  end

  def results_data
    @results_data ||= session[RESULTS_KEY]
  end

  def session_expired?
    return true unless update_data&.dig("timestamp")
    
    Time.parse(update_data["timestamp"]) < SESSION_TIMEOUT.ago
  end

  def cleanup_expired_sessions
    clear_session_data if session_expired?
  end

  def require_update_session
    if update_data.blank? || session_expired?
      flash[:alert] = session_expired? ? 
        I18n.t('bulk_price_updates.session_expired') :
        I18n.t('bulk_price_updates.session_not_found')
      redirect_to new_bulk_price_update_path
      return false
    end
    true
  end
end 