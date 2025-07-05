require "test_helper"

class StoreControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get store_show_url
    assert_response :success
  end

  test "should get edit" do
    get store_edit_url
    assert_response :success
  end

  test "should get update" do
    get store_update_url
    assert_response :success
  end
end
