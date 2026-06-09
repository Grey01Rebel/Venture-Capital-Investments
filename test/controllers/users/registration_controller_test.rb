require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # user registration
  test "user can register with valid attributes including full_name" do
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          full_name: "New Investor",
          email: "newinvestor@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
  end

  test "registration creates a wallet for the new user" do
    assert_difference "Wallet.count", 1 do
      post user_registration_path, params: {
        user: {
          full_name: "Wallet Test User",
          email: "wallettest@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
  end

  test "registration fails without full_name" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          full_name: "",
          email: "nofullname@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
  end

  test "registration fails with mismatched passwords" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          full_name: "Bad Password User",
          email: "badpassword@example.com",
          password: "password123",
          password_confirmation: "different456"
        }
      }
    end
  end

  # email confirmation flow
  test "new user is unconfirmed after registration" do
    post user_registration_path, params: {
      user: {
        full_name: "Unconfirmed User",
        email: "unconfirmed@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
    user = User.find_by(email: "unconfirmed@example.com")
    assert_not user.confirmed?
  end

  test "user can confirm account with valid token" do
    post user_registration_path, params: {
      user: {
        full_name: "Confirm Me",
        email: "confirmme@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
    user = User.find_by(email: "confirmme@example.com")
    get user_confirmation_path, params: { confirmation_token: user.confirmation_token }
    user.reload
    assert user.confirmed?
  end
end