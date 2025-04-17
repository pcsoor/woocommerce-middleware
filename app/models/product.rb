class Product < ApplicationRecord
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :id, :name, :regular_price, :stock_quantity, :manage_stock, :type

  def persisted?
    id.present?
  end

  def self.from_woocommerce(hash)
    new(
      id: hash["id"],
      name: hash["name"],
      regular_price: hash["regular_price"],
      stock_quantity: hash["stock_quantity"],
      manage_stock: hash["manage_stock"],
      type: hash["type"]
    )
  end

  def to_woocommerce_payload
    {
      name: name,
      regular_price: regular_price.to_s,
      stock_quantity: stock_quantity,
      manage_stock: true,
      type: type
    }.compact
  end
end
