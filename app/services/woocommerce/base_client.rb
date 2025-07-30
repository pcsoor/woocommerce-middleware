# app/services/woocommerce/base_client.rb
require 'faraday'
require 'faraday/retry'
require 'base64'
require 'ostruct'
require 'open3'

module Woocommerce
  class BaseClient
    def initialize(store)
      @store = store
      @api_url = "#{store.api_url.chomp('/')}/wp-json/wc/v3/"
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
      endpoint = endpoint.sub(/^\//, '')
      Rails.logger.info("WooCommerce API #{method.upcase} #{@api_url}#{endpoint}")

      # Always use system curl for pigmentvarazs.hu due to CDN/networking issues
      if @api_url.include?('pigmentvarazs.hu')
        return system_curl_request(method, endpoint, query, body)
      end

      # Use normal Faraday for other domains
      response = connection.public_send(method, endpoint) do |req|
        req.params = query if query.present?
        req.body = body if body.present?
      end

      ResponseWrapper.new(response).tap do |wrapped_response|
        Rails.logger.info("WooCommerce API #{method.upcase} #{endpoint}: #{wrapped_response.code}")
      end
    rescue Faraday::Error => e
      Rails.logger.error("WooCommerce API error: #{e.message}")
      raise StandardError, "Network error connecting to WooCommerce: #{e.message}"
    end

    def system_curl_request(method, endpoint, query, body)
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
        '--connect-timeout', '15',
        '--max-time', '30'
      ]

      if body.present? && %w[POST PUT].include?(method_str)
        cmd << '-d'
        cmd << body.to_json
      end

      cmd << url

      Rails.logger.info("Executing curl command to: #{url}")
      Rails.logger.debug("Full command: #{cmd.inspect}")

      begin
        # Execute the command
        stdout, stderr, status = Open3.capture3(*cmd)

        Rails.logger.debug("Curl stdout length: #{stdout.length}")
        Rails.logger.debug("Curl stderr: #{stderr}") if stderr.present?
        Rails.logger.debug("Curl exit status: #{status.exitstatus}")

        if status.success? && stdout.include?("\r\n\r\n")
          header_section, body_section = stdout.split("\r\n\r\n", 2)
          headers = parse_curl_headers(header_section)
          status_code = extract_status_from_headers(header_section)
        else
          Rails.logger.error("Curl failed with status #{status.exitstatus}: #{stderr}")
          headers = { 'content-type' => 'application/json' }
          body_section = stdout.presence || stderr || '{"error": "Request failed"}'
          status_code = status.success? ? 200 : 500
        end

        # Create a mock Faraday response
        mock_response = OpenStruct.new(
          status: status_code,
          body: body_section,
          headers: headers
        )

        ResponseWrapper.new(mock_response).tap do |wrapped_response|
          Rails.logger.info("WooCommerce API #{method_str} #{endpoint}: #{wrapped_response.code}")
        end
      rescue => e
        Rails.logger.error("Error in system_curl_request: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        raise
      end
    end

    def build_url(endpoint, query)
      url = "#{@api_url}#{endpoint}"
      url += "?#{query.to_query}" if query.present?
      url
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

    def connection
      @connection ||= Faraday.new(url: @api_url) do |conn|
        conn.request :authorization, :basic, @store.consumer_key, @store.consumer_secret
        conn.request :json
        conn.response :json, content_type: /\bjson$/

        conn.request :retry, max: 2, interval: 1, backoff_factor: 1.5

        conn.options.timeout = 30
        conn.options.open_timeout = 15

        conn.headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'User-Agent' => 'WooCommerce-Middleware/1.0'
        }

        conn.adapter :net_http
      end
    end
  end
end