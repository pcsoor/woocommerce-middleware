class Store < ApplicationRecord
  belongs_to :user

  encrypts :consumer_key
  encrypts :consumer_secret

  validates :api_url, :consumer_key, :consumer_secret, presence: true
  validates :name, presence: true, length: { maximum: 100 }
  validates :consumer_key, length: { minimum: 10, maximum: 200 }
  validates :consumer_secret, length: { minimum: 10, maximum: 200 }
  
  validate :api_url_format
  validate :api_url_accessible, unless: :skip_url_check?
  
  before_validation :sanitize_inputs

  def established?
    api_url.present? && consumer_key.present? && consumer_secret.present?
  end

  private

  def sanitize_inputs
    self.api_url = api_url&.strip&.downcase
    self.name = name&.strip
    self.consumer_key = consumer_key&.strip
    self.consumer_secret = consumer_secret&.strip
  end

  def api_url_format
    return if api_url.blank?

    begin
      uri = URI.parse(api_url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:api_url, "Must be a valid HTTP or HTTPS URL")
        return
      end

      if Rails.env.production? && uri.scheme != 'https'
        errors.add(:api_url, "Must use HTTPS for security in production")
      end

      if uri.host.blank? || uri.host.start_with?(".") || uri.host.end_with?(".") || uri.host.include?("..")
        errors.add(:api_url, "Must include a valid hostname")
      end

      # Basic domain validation
      unless uri.host.match?(/\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}\z/)
        errors.add(:api_url, "Must be a valid domain name")
      end
    rescue URI::InvalidURIError
      errors.add(:api_url, "Invalid URL format")
    end
  end

  def skip_url_check?
    Rails.env.development? || Rails.env.test?
  end

  def api_url_accessible
    return if api_url.blank? || errors[:api_url].any?

    begin
      # Basic connectivity check
      uri = URI.parse(api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 3
      http.read_timeout = 3
      
      response = http.head('/')
      unless response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
        errors.add(:api_url, "URL is not accessible (#{response.code})")
      end
    rescue => e
      Rails.logger.warn("Store URL check failed: #{e.message}")
      errors.add(:api_url, "Cannot connect to the provided URL: #{e.message}")
    end
  end
end
