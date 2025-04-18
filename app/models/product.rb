class Product < ApplicationRecord
  include ActiveModel::Model
  include ActiveModel::Attributes

  ATTRIBUTES = %i[id sku name regular_price status stock_quantity manage_stock type images]

  attr_accessor(*ATTRIBUTES)

  def self.from_woocommerce(hash)
    product = new
    ATTRIBUTES.each do |attr|
      product.send("#{attr}=", hash[attr.to_s])
    end
    product
  end

  def to_woocommerce_payload
    ATTRIBUTES.each_with_object({}) do |attr, payload|
      value = send(attr)
      payload[attr] = value if value.present?
    end
  end

  def persisted?
    id.present?
  end
end
