class Product
  include ActiveModel::Model
  include ActiveModel::Validations

  ATTRIBUTES = %i[
    id sku name regular_price sale_price stock_quantity manage_stock
    type status featured short_description description weight images
  ].freeze

  attr_accessor(*ATTRIBUTES)
  attr_reader :warnings

  validates :sku, :name, :regular_price, presence: true
  validates :regular_price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :stock_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_blank: true

  def initialize(attributes = {})
    super
    @warnings = []
  end

  def attributes
    ATTRIBUTES.each_with_object({}) do |attr, hash|
      hash[attr.to_s] = public_send(attr)
    end
  end

  def self.from_woocommerce(hash)
    new.tap do |product|
      ATTRIBUTES.each do |attr|
        product.public_send("#{attr}=", hash[attr.to_s])
      end
    end
  end

  def to_woocommerce_payload
    attributes.compact
  end

  def persisted?
    id.present?
  end

  def add_warning(message)
    @warnings << message unless @warnings.include?(message)
  end

  def has_warnings?
    @warnings.any?
  end

  def clear_warnings
    @warnings.clear
  end
end
