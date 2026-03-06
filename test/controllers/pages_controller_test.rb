require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET root renders showcase for unauthenticated visitors" do
    get root_path
    assert_response :success
  end
end
