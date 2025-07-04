class Store < ApplicationRecord
  belongs_to :user

  encrypts :consumer_key
  encrypts :consumer_secret

  validates :api_url, :consumer_key, :consumer_secret, presence: true
  validate :api_url_format

  private

  def api_url_format
    return if api_url.blank?

    begin
      uri = URI.parse(api_url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:api_url, "Invalid URL format")
        return
      end

      if uri.host.blank? || uri.host.start_with?(".") || uri.host.end_with?(".") || uri.host.include?("..")
        errors.add(:api_url, "API URL must include host")
      end
    rescue URI::InvalidURIError
      errors.add(:api_url, "Invalid URL")
    end
  end
end
