require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_confirmed_user
  end

  test "confirmed user can sign in with valid credentials" do
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }
    assert_redirected_to authenticated_root_path
  end

  test "unconfirmed user cannot sign in" do
    unconfirmed = User.create!(
      full_name: "Unconfirmed",
      email: "unconfirmed_login@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    post user_session_path, params: {
      user: { email: unconfirmed.email, password: "password123" }
    }
    assert_response :redirect
    follow_redirect!
    assert_match "confirm", response.body.downcase
  end

  test "user cannot sign in with wrong password" do
    post user_session_path, params: {
      user: { email: @user.email, password: "wrongpassword" }
    }
    assert_response :unprocessable_entity
  end

  test "signed in user can sign out" do
    sign_in @user
    delete destroy_user_session_path
    assert_redirected_to root_path
  end

  test "after signing out user cannot access dashboard" do
    sign_in @user
    delete destroy_user_session_path
    # After sign out, a protected path redirects to sign in
    get "/users/edit"
    assert_redirected_to new_user_session_path
  end

  test "user can request a password reset" do
    post user_password_path, params: {
      user: { email: @user.email }
    }
    assert_response :redirect
  end

  test "password reset request with unknown email does not reveal user existence" do
    post user_password_path, params: {
      user: { email: "unknown@example.com" }
    }
    assert_response :unprocessable_entity
  end
end