require "test_helper"

class VariationsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get variations_edit_url
    assert_response :success
  end

  test "should get update" do
    get variations_update_url
    assert_response :success
  end
end
