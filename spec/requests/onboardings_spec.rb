require "rails_helper"

RSpec.describe "/onboardings", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET /onboardings/new" do
    context "when user has store assigned" do
      let(:user) { create(:user, :with_store) }

      before do
        sign_in user, scope: :user
        get new_onboardings_path
      end

      it "redirects to products index" do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when user has no store assigned" do
      let(:user) { create(:user) }

      before do
        sign_in user, scope: :user
        get root_url
      end

      it "redirects to onboarding page" do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_onboardings_path)
      end
    end
  end

  describe "POST /onboardings" do
    let(:user) { create(:user) }
    let(:store_attributes) { attributes_for(:store) }
    let(:valid_attributes) do
      {
        api_url: store_attributes[:api_url],
        consumer_key: store_attributes[:consumer_key],
        consumer_secret: store_attributes[:consumer_secret]
      }
    end
    let(:invalid_attributes) do
      {
        api_url: "",
        consumer_key: "",
        consumer_secret: ""
      }
    end

    before do
      sign_in user, scope: :user
    end

    context "with valid parameters and successful API validation" do
      before do
        stub_request(:get, "#{store_attributes[:api_url]}/wp-json/wc/v3/")
          .with(
            basic_auth: [
              store_attributes[:consumer_key],
              store_attributes[:consumer_secret]
            ],
          )
          .to_return(status: 200, body: { success: true }.to_json)
      end

      it "creates a new store" do
        expect {
          post onboardings_path, params: { store: valid_attributes }
        }.to change(Store, :count).by(1)
      end

      it "associates the store with current user" do
        post onboardings_path, params: { store: valid_attributes }
        expect(user.reload.store).to be_present
      end

      it "redirects to products path with success notice" do
        post onboardings_path, params: { store: valid_attributes }
        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq("Store connected successfully.")
      end

      it "makes API call to validate credentials" do
        post onboardings_path, params: { store: valid_attributes }

        expect(a_request(:get, "#{store_attributes[:api_url]}/wp-json/wc/v3/")
                 .with(basic_auth: [ store_attributes[:consumer_key], store_attributes[:consumer_secret] ])
        ).to have_been_made
      end
    end

    context "with invalid store parameters" do
      it "does not create a store" do
        expect {
          post onboardings_path, params: { store: invalid_attributes }
        }.not_to change(Store, :count)
      end

      it "renders the new template with validation errors" do
        post onboardings_path, params: { store: invalid_attributes }
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq("Failed to save store configuration.")
      end

      it "assigns @store with errors for the form" do
        post onboardings_path, params: { store: invalid_attributes }
        expect(assigns(:store)).to be_a(Store)
        expect(assigns(:store).errors).to be_present
      end
    end

    context "with failed API validation" do
      before do
        stub_request(:get, "https://random-url.com/wp-json/wc/v3/")
          .to_return(status: 401, body: { message: "Unauthorized" }.to_json)
      end

      it "does not create a store" do
        expect {
          post onboardings_path, params: { store: valid_attributes }
        }.not_to change(Store, :count)
      end

      it "renders the new template with error message" do
        post onboardings_path, params: { store: valid_attributes }
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq("Invalid WooCommerce API credentials.")
      end
    end
  end
end
