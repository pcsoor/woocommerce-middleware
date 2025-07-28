# app/services/woocommerce/response_wrapper.rb
module Woocommerce
  class ResponseWrapper
    attr_reader :status, :headers, :body

    def initialize(faraday_response)
      @status = faraday_response.status
      @headers = faraday_response.headers
      @body = faraday_response.body
    end

    def success?
      (200..299).cover?(status)
    end

    def code
      status
    end

    def parsed_response
      @parsed_response ||= parse_body
    end

    def message
      case parsed_response
      when Hash
        parsed_response['message'] || parsed_response[:message]
      else
        body.to_s
      end
    end

    private

    def parse_body
      case body
      when String
        parse_json_string
      when Hash, Array
        body
      else
        body
      end
    end

    def parse_json_string
      return body if body.strip.empty?

      JSON.parse(body)
    rescue JSON::ParserError => e
      Rails.logger.debug("JSON parse failed: #{e.message}")
      body
    end
  end
end