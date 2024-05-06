require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get reports_home_url
    assert_response :success
  end

  test "should get range" do
    get reports_range_url
    assert_response :success
  end

  test "should get mttm" do
    get reports_mttm_url
    assert_response :success
  end
end
