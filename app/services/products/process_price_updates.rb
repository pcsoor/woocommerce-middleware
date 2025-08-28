module Products
  class ProcessPriceUpdates
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user
    attribute :products, default: -> { [] }

    validates :user, presence: true
    validate :products_must_be_valid

    def self.call(user, products)
      new(user: user, products: products).call
    end

    def call
      return error_result("Invalid parameters") unless valid?

      reset_counters
      process_all_products
      build_result
    end

    private

    attr_accessor :updated_count, :created_count, :failed_count, :errors_list

    def reset_counters
      @updated_count = 0
      @created_count = 0
      @failed_count = 0
      @errors_list = []
    end

    def process_all_products
      products.each { |product| process_single_product(product) }
    end

    def process_single_product(product)
      return unless product.valid?

      existing_product = find_existing_product(product.sku)
      
      if existing_product
        update_existing_product(existing_product, product)
      else
        create_new_product(product)
      end
    rescue StandardError => e
      handle_product_error(product, e)
    end

    def find_existing_product(sku)
      response = woocommerce_client.get_products(sku: sku, per_page: 1)
      response.success? && response.parsed_response.any? ? response.parsed_response.first : nil
    end

    def update_existing_product(existing_product, new_product_data)
      update_payload = build_update_payload(existing_product, new_product_data)
      response = woocommerce_client.update_product(existing_product['id'], update_payload)

      if response.success?
        handle_update_success(new_product_data, existing_product['id'])
      else
        handle_update_failure(new_product_data, response)
      end
    end

    def create_new_product(product)
      create_payload = build_create_payload(product)
      response = woocommerce_client.create_product(create_payload)

      if response.success?
        handle_create_success(product)
      else
        handle_create_failure(product, response)
      end
    end

    def build_update_payload(existing_product, new_product_data)
      payload = { regular_price: new_product_data.regular_price.to_s }

      if new_product_data.name.present? && new_product_data.name != existing_product['name']
        payload[:name] = new_product_data.name
      end
      
      payload
    end

    def build_create_payload(product)
      {
        name: product.name || "Product #{product.sku}",
        sku: product.sku,
        regular_price: product.regular_price.to_s,
        type: 'simple',
        status: 'publish',
        manage_stock: false
      }
    end

    def handle_update_success(product, product_id)
      @updated_count += 1
      Rails.logger.info("Updated price for SKU #{product.sku}: #{product.regular_price}")
      invalidate_product_cache(product_id)
    end

    def handle_create_success(product)
      @created_count += 1
      Rails.logger.info("Created new product SKU #{product.sku}: #{product.regular_price}")
      invalidate_user_cache
    end

    def handle_update_failure(product, response)
      @failed_count += 1
      error_msg = "Failed to update SKU #{product.sku}: #{extract_error_message(response)}"
      @errors_list << error_msg
      Rails.logger.error(error_msg)
    end

    def handle_create_failure(product, response)
      @failed_count += 1
      error_msg = "Failed to create SKU #{product.sku}: #{extract_error_message(response)}"
      @errors_list << error_msg
      Rails.logger.error(error_msg)
    end

    def handle_product_error(product, error)
      @failed_count += 1
      error_msg = "Failed to process SKU #{product.sku}: #{error.message}"
      @errors_list << error_msg
      Rails.logger.error(error_msg)
    end

    def extract_error_message(response)
      response.parsed_response['message'] rescue 'Unknown error'
    end

    def invalidate_product_cache(product_id)
      ProductCache.invalidate_product(user.id, product_id)
    end

    def invalidate_user_cache
      ProductCache.invalidate_all_user_cache(user.id)
    end

    def woocommerce_client
      @woocommerce_client ||= Woocommerce::ProductsClient.new(user.store)
    end

    def build_result
      OpenStruct.new(
        success?: failed_count.zero?,
        updated_count: updated_count,
        created_count: created_count,
        failed_count: failed_count,
        errors: errors_list
      )
    end

    def error_result(message)
      OpenStruct.new(
        success?: false,
        updated_count: 0,
        created_count: 0,
        failed_count: 0,
        errors: [message]
      )
    end

    def products_must_be_valid
      return if products.is_a?(Array)
      
      errors.add(:products, "must be an array")
    end
  end
end 