module ApplicationHelper
  def extract_store_name(api_url)
    return unless api_url.present?

    uri = URI.parse(api_url)
    domain = uri.host

    domain&.sub(/^www\./, "")
  rescue URI::InvalidURIError
    nil
  end
end
