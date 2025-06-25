FactoryBot.define do
  factory :product, class: "Product" do
    skip_create

    sequence(:id) { |n| n }
    name { "Test Product" }
    sku { "SKU-#{id}" }
    regular_price { 1234 }
    stock_quantity { 10 }
  end
end
