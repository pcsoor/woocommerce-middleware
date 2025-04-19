class Product < ApplicationRecord
  include ActiveModel::Model
  include ActiveModel::Attributes

  ATTRIBUTES = %i[
    id
    name
    regular_price
    sale_price
    stock_quantity
    manage_stock
    sku
    type
    status
    featured
    short_description
    description
    categories
    tags
    images
    weight
    dimensions
    downloadable
    virtual
    meta_data
  ]

  validates :name, presence: true
  validates :regular_price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :stock_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_blank: true

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
