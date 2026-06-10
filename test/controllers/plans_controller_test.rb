require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user  = create_confirmed_user
    @plans = create_all_six_plans
  end

  test "authenticated user can access plans page" do
    sign_in @user
    get plans_path
    assert_response :success
  end

  test "unauthenticated user is redirected to sign in" do
    get plans_path
    assert_redirected_to new_user_session_path
  end

  test "plans are returned in position order" do
    sign_in @user
    get plans_path
    assert_response :success
    positions = InvestmentPlan.visible.map(&:position)
    assert_equal positions.sort, positions
  end

  test "inactive plans do not appear on the plans page" do
    inactive = create_investment_plan(active: false)
    sign_in @user
    get plans_path
    assert_response :success
    assert_no_match inactive.name, response.body
  end

  test "all six active plans appear on the plans page" do
    sign_in @user
    get plans_path
    %w[Starter Bronze Silver Gold Platinum VIP].each do |name|
      assert_match name, response.body
    end
  end

  test "plans page displays investment amounts in USD format" do
    sign_in @user
    get plans_path
    assert_match "$500.00", response.body
  end

  test "plans page displays daily return rates with percent symbol" do
    sign_in @user
    get plans_path
    assert_match "%", response.body
  end

  test "plans page displays duration in days format" do
    sign_in @user
    get plans_path
    assert_match "14 Days", response.body
  end
end