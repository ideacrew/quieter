require "test_helper"

class AhaControllerTest < ActionDispatch::IntegrationTest
  test "should get explorer" do
    get aha_explorer_url
    assert_response :success
  end
end
