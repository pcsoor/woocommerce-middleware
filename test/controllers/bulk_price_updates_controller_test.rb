require "test_helper"

class BulkPriceUpdatesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get bulk_price_updates_new_url
    assert_response :success
  end

  test "should get create" do
    get bulk_price_updates_create_url
    assert_response :success
  end
end
