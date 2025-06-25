require "rails_helper"

RSpec.describe Products::FetchProducts do
  let(:user) { create(:user) }
  let!(:store) { create(:store, user: user) }
  let(:mock_client) { instance_double(Woocommerce::ProductsClient) }
  let(:mock_response) { double('response') }

  let(:woocommerce_product_data) do
    [
      {
        "id" => 123,
        "name" => "Test Product 1",
        "price" => "19.99",
        "sku" => "TEST-SKU-1",
        "status" => "publish"
      },
      {
        "id" => 124,
        "name" => "Test Product 2",
        "price" => "29.99",
        "sku" => "TEST-SKU-2",
        "status" => "publish"
      }
    ]
  end

  before do
    allow(Woocommerce::ProductsClient).to receive(:new).with(store).and_return(mock_client)
    allow(Rails.cache).to receive(:write)
  end

  describe '.call' do
    it 'delegates to instance method' do
      service_instance = instance_double(described_class)
      allow(described_class).to receive(:new).with(user, 1, 25).and_return(service_instance)
      allow(service_instance).to receive(:call).and_return([])

      described_class.call(user, page: 1, per_page: 25)

      expect(described_class).to have_received(:new).with(user, 1, 25)
      expect(service_instance).to have_received(:call)
    end
  end

  describe '#call' do
    subject(:service) { described_class.new(user, page, per_page) }
    let(:page) { 1 }
    let(:per_page) { 25 }

    context 'when API request is successful' do
      before do
        allow(mock_response).to receive(:success?).and_return(true)
        allow(mock_response).to receive(:parsed_response).and_return(woocommerce_product_data)
        allow(mock_response).to receive(:headers).and_return({ "x-wp-total" => "50" })
        allow(mock_client).to receive(:get_products).and_return(mock_response)
        allow(mock_client).to receive(:cache_key_for).and_return("cache_key")

        # Mock Product.from_woocommerce
        allow(Product).to receive(:from_woocommerce).and_return(instance_double(Product))
      end

      it 'fetches products from WooCommerce API' do
        service.call

        expect(mock_client).to have_received(:get_products).with(page: 1, per_page: 25)
      end

      it 'caches each product' do
        service.call

        woocommerce_product_data.each do |product_data|
          expect(mock_client).to have_received(:cache_key_for).with(user.id, product_data["id"])
          expect(Rails.cache).to have_received(:write).with(
            "cache_key",
            product_data,
            expires_in: 10.minutes
          )
        end
      end

      it 'converts WooCommerce data to Product objects' do
        service.call

        woocommerce_product_data.each do |product_data|
          expect(Product).to have_received(:from_woocommerce).with(product_data)
        end
      end

      it 'returns paginated results' do
        result = service.call

        expect(result).to respond_to(:current_page)
        expect(result).to respond_to(:total_pages)
        expect(result).to respond_to(:total_count)
        expect(result.total_count).to eq(50)
        expect(result.current_page).to eq(1)
      end

      it 'handles custom pagination parameters' do
        service = described_class.new(user, 2, 10)
        allow(mock_client).to receive(:get_products).with(page: 2, per_page: 10).and_return(mock_response)

        service.call

        expect(mock_client).to have_received(:get_products).with(page: 2, per_page: 10)
      end
    end

    context 'when API request fails' do
      before do
        allow(mock_response).to receive(:success?).and_return(false)
        allow(mock_client).to receive(:get_products).and_return(mock_response)
      end

      it 'raises an error' do
        expect { service.call }.to raise_error(StandardError, "Failed to fetch products from WooCommerce")
      end

      it 'does not cache any products' do
        expect { service.call }.to raise_error(StandardError)
        expect(Rails.cache).not_to have_received(:write)
      end

      it 'does not convert any products' do
        expect { service.call }.to raise_error(StandardError)
        expect(Product).not_to receive(:from_woocommerce)
      end
    end

    context 'when client raises an exception' do
      before do
        allow(mock_client).to receive(:get_products).and_raise(Net::ReadTimeout)
      end

      it 'propagates the exception' do
        expect { service.call }.to raise_error(Net::ReadTimeout)
      end
    end

    context 'with edge cases' do
      before do
        allow(mock_response).to receive(:success?).and_return(true)
        allow(mock_client).to receive(:get_products).and_return(mock_response)
        allow(mock_client).to receive(:cache_key_for).and_return("cache_key")
        allow(Product).to receive(:from_woocommerce).and_return(instance_double(Product))
      end

      it 'handles empty product list' do
        allow(mock_response).to receive(:parsed_response).and_return([])
        allow(mock_response).to receive(:headers).and_return({ "x-wp-total" => "0" })

        result = service.call

        expect(result.total_count).to eq(0)
        expect(result.to_a).to be_empty
      end

      it 'handles missing x-wp-total header' do
        allow(mock_response).to receive(:parsed_response).and_return(woocommerce_product_data)
        allow(mock_response).to receive(:headers).and_return({})

        result = service.call

        expect(result.total_count).to eq(0)
      end

      it 'handles string page and per_page parameters' do
        service = described_class.new(user, "2", "10")
        allow(mock_response).to receive(:parsed_response).and_return([])
        allow(mock_response).to receive(:headers).and_return({ "x-wp-total" => "0" })
        allow(mock_client).to receive(:get_products).with(page: "2", per_page: "10").and_return(mock_response)

        expect { service.call }.not_to raise_error
      end
    end
  end
end
