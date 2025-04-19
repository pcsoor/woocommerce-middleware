class Category
  include ActiveModel::Model
  include ActiveModel::Attributes

  ATTRIBUTES = %i[
    id
    name
    slug
    description
    count
    parent
  ]

  attr_accessor(*ATTRIBUTES)

  def self.from_woocommerce(hash)
    category = new
    ATTRIBUTES.each do |attr|
      category.send("#{attr}=", hash[attr.to_s])
    end
    category
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
