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
    Rails.env.test? || Rails.env.production?
  end

  def api_url_accessible
    return if api_url.blank? || errors[:api_url].any?

    begin
      uri = URI.parse(api_url)
      
      timeout_config = {
        open_timeout: 45,
        read_timeout: 60,
        ssl_timeout: 30
      }
      
      Rails.logger.info("Testing connectivity to: #{api_url} with timeouts: #{timeout_config}")
      
      Net::HTTP.start(uri.host, uri.port, 
                     use_ssl: uri.scheme == 'https',
                     verify_mode: OpenSSL::SSL::VERIFY_PEER,
                     **timeout_config) do |http|
        
        response = http.get('/')
        
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          Rails.logger.info("Store URL check successful: #{response.code}")
        when Net::HTTPNotFound
          Rails.logger.info("Store URL check successful (404 is acceptable): #{response.code}")
        when Net::HTTPUnauthorized, Net::HTTPForbidden
          Rails.logger.info("Store URL check successful (auth required): #{response.code}")
        else
          Rails.logger.warn("Store URL check failed with status: #{response.code}")
          errors.add(:api_url, "URL is not accessible (HTTP #{response.code})")
        end
      end
      
    rescue Net::OpenTimeout => e
      Rails.logger.warn("Store URL connection timeout: #{e.message}")
      errors.add(:api_url, "Connection timeout: The server is taking too long to respond. Please check the URL.")
      
    rescue Net::ReadTimeout => e
      Rails.logger.warn("Store URL read timeout: #{e.message}")
      errors.add(:api_url, "Read timeout: The server is not responding fast enough. Please check the URL.")
      
    rescue OpenSSL::SSL::SSLError => e
      Rails.logger.warn("Store URL SSL error: #{e.message}")
      errors.add(:api_url, "SSL connection error: #{e.message}")
      
    rescue Errno::ECONNREFUSED => e
      Rails.logger.warn("Store URL connection refused: #{e.message}")
      errors.add(:api_url, "Connection refused: The server is not accepting connections.")
      
    rescue Errno::EHOSTUNREACH, Errno::ENETUNREACH => e
      Rails.logger.warn("Store URL host unreachable: #{e.message}")
      errors.add(:api_url, "Host unreachable: Cannot reach the server.")
      
    rescue SocketError => e
      Rails.logger.warn("Store URL DNS error: #{e.message}")
      errors.add(:api_url, "DNS error: Cannot resolve hostname. Please check the URL.")
      
    rescue => e
      Rails.logger.warn("Store URL check failed: #{e.class} - #{e.message}")
      errors.add(:api_url, "Cannot connect to the provided URL: #{e.message}")
    end
  end
end
