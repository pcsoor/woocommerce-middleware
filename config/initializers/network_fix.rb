require 'resolv-replace'

# Configure Net::HTTP defaults for container environment
class Net::HTTP
  alias_method :original_initialize, :initialize

  def initialize(address, port = nil)
    original_initialize(address, port)

    # Force IPv4 resolution
    begin
      @address = Resolv.getaddress(address) if address.is_a?(String)
    rescue Resolv::ResolvError
      # Fallback to original address if resolution fails
      @address = address
    end

    # Increase timeouts for container environment
    @open_timeout = 30
    @read_timeout = 60
    @ssl_timeout = 30

    # Use system CA certificates
    if use_ssl?
      self.verify_mode = OpenSSL::SSL::VERIFY_PEER
      self.ca_file = '/etc/ssl/certs/ca-certificates.crt' if File.exist?('/etc/ssl/certs/ca-certificates.crt')
    end
  end
end

Rails.logger.info "Network fix initializer loaded - forcing IPv4 and extended timeouts"