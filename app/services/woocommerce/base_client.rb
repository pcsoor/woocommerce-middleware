require 'open3'
require 'json'

module Woocommerce
  class BaseClient
    def initialize(store)
      @api_url = store.api_url.chomp("/") + "/wp-json/wc/v3/"
      @store = store
    end

    def get(endpoint, query: {})
      request(:get, endpoint, query: query)
    end

    def post(endpoint, body: {}, query: {})
      request(:post, endpoint, query: query, body: body)
    end

    def put(endpoint, body: {}, query: {})
      request(:put, endpoint, query: query, body: body)
    end

    def delete(endpoint, query: {})
      request(:delete, endpoint, query: query)
    end

    private

    def request(method, endpoint, query: {}, body: nil)
      url = build_url(endpoint, query)
      auth = Base64.strict_encode64("#{@store.consumer_key}:#{@store.consumer_secret}")

      # Ensure method is a string
      method_str = method.to_s.upcase

      # Build the curl command properly
      cmd = [
        'curl',
        '-s',
        '-i',
        '-X', method_str,
        '-H', "Authorization: Basic #{auth}",
        '-H', 'Content-Type: application/json',
        '-H', 'Accept: application/json',
        '-H', 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        '--connect-timeout', '15',
        '--max-time', '30'
      ]

      if body.present? && %w[POST PUT].include?(method_str)
        cmd << '-d'
        cmd << body.to_json
      end

      cmd << url

      Rails.logger.info("WooCommerce API: #{method_str} #{url}")

      # Execute with retries
      max_attempts = 3
      attempts = 0

      loop do
        attempts += 1

        begin
          # Execute the command
          stdout, stderr, status = Open3.capture3(*cmd)

          Rails.logger.debug("Curl attempt #{attempts}: stdout length: #{stdout.length}, exit status: #{status.exitstatus}")
          Rails.logger.debug("Curl stderr: #{stderr}") if stderr.present?

          if status.success? && stdout.include?("\r\n\r\n")
            header_section, body_section = stdout.split("\r\n\r\n", 2)
            headers = parse_curl_headers(header_section)
            status_code = extract_status_from_headers(header_section)

            # Create response object
            response = OpenStruct.new(
              code: status_code,
              body: body_section,
              headers: headers,
              success?: status_code >= 200 && status_code < 300
            )

            Rails.logger.info("WooCommerce API response: #{method_str} #{endpoint} - Status: #{status_code}")

            return Woocommerce::Response.new(response)
          else
            error_msg = "Curl failed with status #{status.exitstatus}: #{stderr}"
            Rails.logger.error(error_msg)

            if attempts < max_attempts
              Rails.logger.warn("Retrying... (attempt #{attempts}/#{max_attempts})")
              sleep(attempts) # Exponential backoff
              next
            else
              # Return error response
              error_response = OpenStruct.new(
                code: 500,
                body: '{"error": "Request failed"}',
                headers: { 'content-type' => 'application/json' },
                success?: false
              )
              return Woocommerce::Response.new(error_response)
            end
          end
        rescue => e
          Rails.logger.error("Error in curl request: #{e.class} - #{e.message}")
          if attempts < max_attempts
            Rails.logger.warn("Retrying after exception... (attempt #{attempts}/#{max_attempts})")
            sleep(attempts)
            next
          else
            raise
          end
        end
      end
    end

    def parse_curl_headers(header_section)
      headers = { 'content-type' => 'application/json' }

      header_section.split("\r\n").each do |line|
        if line.include?(': ')
          key, value = line.split(': ', 2)
          headers[key.downcase] = value
        end
      end

      headers
    end

    def extract_status_from_headers(header_section)
      return 200 unless header_section

      status_line = header_section.split("\r\n").first
      if status_line && (match = status_line.match(/HTTP\/[\d\.]+\s+(\d+)/))
        match[1].to_i
      else
        200
      end
    end

    def build_url(endpoint, query)
      url = "#{@api_url}#{endpoint.sub(/^\//, '')}"
      if query.present?
        url += "?#{query.to_query}"
      end
      url
    end
  end
end