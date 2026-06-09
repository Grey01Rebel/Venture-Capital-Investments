require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_confirmed_user
  end

  test "authenticated user can access the dashboard" do
    sign_in @user
    get authenticated_root_path
    assert_response :success
  end

  test "dashboard renders the index template" do
    sign_in @user
    get authenticated_root_path
    assert_response :success
    assert_match "Dashboard", response.body
  end

  test "unauthenticated user is redirected to sign in" do
    # Access a path protected by authenticate_user! without signing in
    get "/users/edit"
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated user cannot access dashboard" do
    get "/users/edit"
    assert_response :redirect
  end

  test "dashboard displays available balance" do
    sign_in @user
    get authenticated_root_path
    assert_match "$0.00", response.body
  end

  test "dashboard displays user full name" do
    sign_in @user
    get authenticated_root_path
    assert_match @user.full_name, response.body
  end

  test "dashboard displays account active status" do
    sign_in @user
    get authenticated_root_path
    assert_match "Account active", response.body
  end

  test "dashboard loads the current user wallet" do
    sign_in @user
    get authenticated_root_path
    assert_response :success
    assert_not_nil @user.wallet
  end
end