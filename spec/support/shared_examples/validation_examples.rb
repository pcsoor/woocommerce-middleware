RSpec.shared_examples "invalid api_url" do |invalid_url, description|
  it "rejects #{description}" do
    store.api_url = invalid_url
    expect(store).not_to be_valid
    expect(store.errors[:api_url]).not_to be_empty
  end
end
