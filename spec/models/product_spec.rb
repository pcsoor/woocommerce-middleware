require 'rails_helper'

RSpec.describe Product, type: :model do
  let(:woo_response) do
    {
      "id" => 123,
      "name" => "Test Product",
      "regular_price" => "100",
      "stock_quantity" => 10,
      "type" => "simple"
    }
  end

  describe "#from_woocommerce" do
    it "creates a Product instance from a WooCommerce hash" do
      product = Product.from_woocommerce(woo_response)

      expect(product.id).to eq(123)
      expect(product.name).to eq("Test Product")
      expect(product.regular_price).to eq("100")
      expect(product.stock_quantity).to eq(10)
      expect(product.type).to eq("simple")
    end
  end

  describe "#to_woocommerce_payload" do
    it "builds correct payload for simple products" do
      product = Product.from_woocommerce(woo_response)

      expect(product.to_woocommerce_payload).to eq({
        id: 123,
        name: "Test Product",
        regular_price: "100",
        stock_quantity: 10,
        type: "simple"
      })
    end
  end
end
