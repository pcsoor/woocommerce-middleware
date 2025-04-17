require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WooCommerce::Client do
  let(:client) do
    WooCommerce::Client.new(
      "https://example.com",
      "ck_test",
      "cs_test"
    )
  end

  it "fetches product variations" do
    stub_request(:get, "https://example.com/wp-json/wc/v3/products/123/variations")
      .with(basic_auth: [ "ck_test", "cs_test" ])
      .to_return(status: 200, body: [ { id: 1 } ].to_json)

    response = client.get_variations(123)
    expect(response.code).to eq(200)
    expect(response.parsed_response.first["id"]).to eq(1)
  end

  it "updates a product variation" do
    stub_request(:put, "https://example.com/wp-json/wc/v3/products/123/variations/456")
      .with(
        basic_auth: [ "ck_test", "cs_test" ],
        body: { regular_price: "100" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
        .to_return(status: 200, body: { id: 456, regular_price: "100" }.to_json)

      response = client.update_variation(123, 456, { regular_price: "100" })
      expect(response.code).to eq(200)
      expect(response.parsed_response["regular_price"]).to eq("100")
  end
end
