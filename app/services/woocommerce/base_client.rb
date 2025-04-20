module Woocommerce
  class BaseClient
    include HTTParty
    format :json

    def initialize(store)
      @api_url = store.api_url.chomp("/") + "/wp-json/wc/v3/"
      @auth = {
        username: store.consumer_key,
        password: store.consumer_secret
      }
      self.class.base_uri(@api_url)
    end

    private

    def request(method, endpoint, query: {}, body: nil)
      attempts ||= 3
      self.class.send(method, endpoint, {
        basic_auth: @auth,
        headers: { "Content-Type" => "application/json" },
        query: query,
        body: body
      })
    rescue Net::ReadTimeout, Errno::ECONNRESET
      attempts -= 1
      retry if attempts > 0
      raise
    end
  end
end
