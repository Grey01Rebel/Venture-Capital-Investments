require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign up and wallet is automatically created" do
    visit new_user_registration_path
    fill_in "Full name", with: "System Test User"
    fill_in "Email address", with: "systemtest@example.com"
    fill_in "Password", with: "password123"
    fill_in "Confirm password", with: "password123"
    click_button "Create account"

    user = User.find_by(email: "systemtest@example.com")
    assert_not_nil user
    assert_not_nil user.wallet
  end

  test "user can confirm account via token" do
    visit new_user_registration_path
    fill_in "Full name", with: "Confirm Test"
    fill_in "Email address", with: "confirmtest@example.com"
    fill_in "Password", with: "password123"
    fill_in "Confirm password", with: "password123"
    click_button "Create account"

    user = User.find_by(email: "confirmtest@example.com")
    visit user_confirmation_path(confirmation_token: user.confirmation_token)
    user.reload
    assert user.confirmed?
  end

  test "confirmed user can log in and see dashboard with wallet statistics" do
    user = User.create!(
      full_name: "Dashboard Viewer",
      email: "dashviewer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.confirm
    login_as user
    visit authenticated_root_path
    assert_current_path authenticated_root_path
    assert_text "Dashboard Viewer"
    assert_text "Available Balance"
    assert_text "Total Deposited"
    assert_text "Total Withdrawn"
    assert_text "Total Profit"
    assert_text "$0.00"
    assert_text "Account active"
  end

  test "signed in user can see sign out button" do
    user = User.create!(
      full_name: "Logout Tester",
      email: "logouttester@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.confirm
    login_as user
    visit authenticated_root_path
    assert_text "Sign Out"
  end

  test "sign in page renders correctly" do
    visit new_user_session_path
    assert_text "Sign in to your account"
    assert_selector "input[type='email']"
    assert_selector "input[type='password']"
  end

  test "sign up page renders with full_name field" do
    visit new_user_registration_path
    assert_text "Create your account"
    assert_selector "input[name='user[full_name]']"
    assert_selector "input[name='user[email]']"
    assert_selector "input[name='user[password]']"
    assert_selector "input[name='user[password_confirmation]']"
  end

  test "registration shows errors when full_name is missing" do
    visit new_user_registration_path
    fill_in "Email address", with: "nofullname@example.com"
    fill_in "Password", with: "password123"
    fill_in "Confirm password", with: "password123"
    click_button "Create account"
    assert_text "Please fix the following"
    assert_text "Full name can't be blank"
  end
end