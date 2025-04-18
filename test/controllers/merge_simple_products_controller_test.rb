require "test_helper"

class MergeSimpleProductsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get merge_simple_products_new_url
    assert_response :success
  end

  test "should get create" do
    get merge_simple_products_create_url
    assert_response :success
  end
end
