require 'rails_helper'

RSpec.describe '/products', type: :request do
  let(:user) { create(:user) }
  let!(:store) { create(:store, user: user) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET /products' do
    context 'when service call is successful' do
      before do
        # Create realistic paginated products
        products = [
          build_stubbed(:product, name: "Product 1"),
          build_stubbed(:product, name: "Product 2")
        ]

        paginated_products = Kaminari.paginate_array(products, total_count: 50)
                                     .page(1)
                                     .per(25)

        allow(Products::FetchProducts).to receive(:call).and_return(paginated_products)
      end

      it 'returns successful response' do
        get products_path
        expect(response).to have_http_status(:success)
      end

      it 'shows products' do
        get products_path
        expect(response.body).to include("Product 1")
        expect(response.body).to include("Product 2")
      end
    end
  end
end
