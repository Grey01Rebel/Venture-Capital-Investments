require "application_system_test_case"

class PlansTest < ApplicationSystemTestCase
  def setup
    @user = User.create!(
      full_name: "Plans Viewer",
      email: "plansviewer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @user.confirm
    create_all_six_plans
  end

  test "authenticated user can visit the plans page" do
    login_as @user
    visit plans_path
    assert_current_path plans_path
    assert_text "Available Plans"
  end

  test "user sees all six investment plans" do
    login_as @user
    visit plans_path
    %w[Starter Bronze Silver Gold Platinum VIP].each do |name|
      assert_text name
    end
  end

  test "user sees plan details including amount, return rate, and duration" do
    login_as @user
    visit plans_path
    assert_text "$500.00"
    assert_text "14 Days"
    assert_text "0.80%"
  end

  test "inactive plans do not appear on the plans page" do
    create_investment_plan(name: "System Hidden Plan", active: false, position: 95)
    login_as @user
    visit plans_path
    assert_no_text "System Hidden Plan"
  end

  test "navbar contains a Plans link for authenticated users" do
    login_as @user
    visit plans_path
    assert_selector "a[href='#{plans_path}']"
  end

  test "unauthenticated user is redirected away from plans page" do
    visit plans_path
    assert_current_path new_user_session_path
  end
end