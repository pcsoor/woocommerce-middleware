module ApplicationHelper
  def extract_store_name
    return "My Store" unless current_user&.store
    api_url = current_user.store.api_url
    return unless api_url.present?

    uri = URI.parse(api_url)
    domain = uri.host

    domain&.sub(/^www\./, "")
  rescue URI::InvalidURIError
    nil
  end

  def current_class?(path)
    return "font-bold text-purple-500" if request.path == path
    "font-medium"
  end
end
