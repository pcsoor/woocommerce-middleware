module WooCommerce
  class MergeSimpleProductsService
    def initialize(store:, products:, attribute_name:, parent_product_name:)
      @store = store
      @products = products
      @attribute_name = attribute_name
      @parent_product_name = parent_product_name
      @client = WooCommerce::Client.new(store.api_url, store.consumer_key, store.consumer_secret)
    end

    def call
      tmp = {
        name: @parent_product_name,
        type: "variable",
        attributes: [
          {
            name: @attribute_name,
            variation: true,
            visible: true,
            options: extract_attribute_options
          }
        ]
      }
      Rails.logger.debug("Payload: #{tmp}")
      # 1. Create parent variable product
      parent_response = @client.create_product(tmp)

      raise "Failed to create parent product: #{parent_response.parsed_response}" unless parent_response.success?

      parent_id = parent_response.parsed_response["id"]

      # 2. Create variations
      @products.each do |product|
        variation_payload = {
          regular_price: product["regular_price"].to_s,
          stock_quantity: product["stock_quantity"],
          manage_stock: true,
          attributes: [
            {
              name: @attribute_name,
              option: extract_option_from_product(product)
            }
          ]
        }

        Rails.logger.debug("Variation Payload: #{variation_payload}")

        variation_response = @client.create_variation(parent_id, variation_payload)

        unless variation_response.success?
          Rails.logger.error "Failed to create variation: #{variation_response.parsed_response}"
          # optionally raise an error here or collect failed variations
        else
          Rails.logger.debug "Created Variation: #{variation_response.parsed_response["id"]}"
        end
      end
    end

    private

    def extract_attribute_options
      @products.map { |p| extract_option_from_product(p) }.uniq
    end

    def extract_option_from_product(product)
      # You need a logic here: maybe from product name? or some metadata?
      # Example: assuming you split name to get color/size
      product["name"].split.last # ← example: "Underwear Red" → "Red"
    end
  end
end
