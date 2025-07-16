module ApplicationHelper
  def extract_store_name
    return t('common.my_store') unless current_user&.store
    api_url = current_user.store.api_url
    return unless api_url.present?

    uri = URI.parse(api_url)
    domain = uri.host

    domain&.sub(/^www\./, "")
  rescue URI::InvalidURIError
    nil
  end

  def current_class?(path)
    if request.path == path
      "text-base-content font-semibold"
    else
      ""
    end
  end

  def flash_class(type)
    case type.to_sym
    when :success
      "alert-success"
    when :error
      "alert-error"
    when :alert
      "alert-warning"
    when :notice
      "alert-info"
    else
      "alert-neutral"
    end
  end

  def flash_icon(type)
    case type.to_sym
    when :success
      icon "check-circle", variant: :mini, class: "h-5 w-5 text-green-400"
    when :error
      icon "x-circle", variant: :mini, class: "h-5 w-5 text-red-400"
    when :alert
      icon "exclamation-triangle", variant: :mini, class: "h-5 w-5 text-yellow-400"
    when :notice
      icon "information-circle", variant: :outline, class: "h-5 w-5 text-blue-400"
    else
      icon "information-circle", variant: :outline, class: "h-5 w-5 text-gray-400"
    end
  end
end
