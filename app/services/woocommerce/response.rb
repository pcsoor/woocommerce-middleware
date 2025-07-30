module Woocommerce
  class Response
    attr_reader :code, :body, :headers, :success

    def initialize(typhoeus_response)
      @code = typhoeus_response.code
      @body = typhoeus_response.body
      @headers = typhoeus_response.headers
      @success = typhoeus_response.success?
      @response = typhoeus_response
    end

    def success?
      @success
    end

    def parsed_response
      @parsed_response ||= begin
                             if @body.present? && @headers['Content-Type']&.include?('application/json')
                               JSON.parse(@body)
                             else
                               @body
                             end
                           rescue JSON::ParserError
                             @body
                           end
    end

    # Delegate any other methods to the original response
    def method_missing(method, *args, &block)
      @response.send(method, *args, &block)
    end

    def respond_to_missing?(method, include_private = false)
      @response.respond_to?(method, include_private)
    end
  end
end