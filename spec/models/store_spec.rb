require "rails_helper"

RSpec.describe Store, type: :model do
  it { is_expected.to validate_presence_of(:api_url) }
  it { is_expected.to validate_presence_of(:consumer_key) }
  it { is_expected.to validate_presence_of(:consumer_secret) }

  describe "store" do
    let(:store) { create(:store) }

    context "when api_url is valid" do
      it "is valid" do
        store.api_url = "http://www.example.com"
        expect(store).to be_valid
      end
    end

    context "when api_url is in wrong format" do
      include_examples "invalid api_url", "invalid-url.com", "URLs without protocol"
      include_examples "invalid api_url", "invalid-url", "malformed URLs"
      include_examples "invalid api_url", "http://", "URLs with protocol only"
      include_examples "invalid api_url", "ftp://example.com", "non-HTTP/HTTPS protocols"
      include_examples "invalid api_url", "http://", "empty domain after protocol"
      include_examples "invalid api_url", "http://.com", "URLs starting with dot"
      include_examples "invalid api_url", "http://example.", "URLs ending with dot"
      include_examples "invalid api_url", "http://ex ample.com", "URLs with spaces"
      include_examples "invalid api_url", "http://example..com", "URLs with double dots"
      include_examples "invalid api_url", "", "empty URLs"
      include_examples "invalid api_url", " ", "whitespace-only URLs"
      include_examples "invalid api_url", "javascript:alert('xss')", "JavaScript URLs"
    end
  end
end
