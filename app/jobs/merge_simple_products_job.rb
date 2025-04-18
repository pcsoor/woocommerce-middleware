
class MergeSimpleProductsJob < ApplicationJob
  queue_as :default

  def perform(store_id, product_ids, attribute_name, parent_product_name)
    store = Store.find(store_id)

    client = WooCommerce::Client.new(
      store.api_url,
      store.consumer_key,
      store.consumer_secret
    )

    response = client.get_products(ids: product_ids)

    if response.success?
      products = response.parsed_response

      WooCommerce::MergeSimpleProductsService.new(
        store: store,
        products: products,
        attribute_name: attribute_name,
        parent_product_name: parent_product_name
      ).call
    else
      Rails.logger.error("Failed to fetch products for merging: #{response.parsed_response}")
    end
  end
end
