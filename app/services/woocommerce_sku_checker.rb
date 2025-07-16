class WoocommerceSkuChecker
  def self.call(sku, store)
    new(sku, store).call
  end

  def initialize(sku, store)
    @sku = sku
    @store = store
  end

  def call
    return false unless valid_inputs?

    response = client.get_products(sku: @sku, per_page: 1)
    response.success? && response.parsed_response.any?
  rescue StandardError => e
    Rails.logger.error("SKU check error for #{@sku}: #{e.message}")
    false
  end

  private

  def valid_inputs?
    @sku.present? && @store.present?
  end

  def client
    @client ||= Woocommerce::ProductsClient.new(@store)
  end
end 