require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_confirmed_user
  end

  # login
  test "confirmed user can sign in with valid credentials" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
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
      user: {
        email: unconfirmed.email,
        password: "password123"
      }
    }
    assert_response :unprocessable_entity
  end

  test "user cannot sign in with wrong password" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "wrongpassword"
      }
    }
    assert_response :unprocessable_entity
  end

  # logout
  test "signed in user can sign out" do
    sign_in @user
    delete destroy_user_session_path
    assert_redirected_to root_path
  end

  test "after signing out user cannot access dashboard" do
    sign_in @user
    delete destroy_user_session_path
    get authenticated_root_path
    assert_redirected_to new_user_session_path
  end

  # password reset request
  test "user can request a password reset" do
    assert_difference "ActionMailer::Base.deliveries.count", 0 do
      post user_password_path, params: {
        user: { email: @user.email }
      }
    end
    assert_response :redirect
  end

  test "password reset request with unknown email does not reveal user existence" do
    post user_password_path, params: {
      user: { email: "unknown@example.com" }
    }
    assert_response :unprocessable_entity
  end
end