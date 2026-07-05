# frozen_string_literal: true
require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @member = create_confirmed_user
  end

  # --- access control ---

  test "admin can access the admin dashboard" do
    sign_in @admin
    get admin_root_path
    assert_response :success
  end

  test "member is redirected from admin dashboard" do
    sign_in @member
    get admin_root_path
    assert_redirected_to authenticated_root_path
  end

  test "unauthenticated user is redirected from admin dashboard" do
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  # --- page content ---

  test "dashboard renders the operations dashboard heading" do
    sign_in @admin
    get admin_root_path
    assert_match "Operations Dashboard", response.body
  end

  test "dashboard displays platform overview section" do
    sign_in @admin
    get admin_root_path
    assert_match "Platform Overview", response.body
    assert_match "Total Users", response.body
    assert_match "Members", response.body
    assert_match "Administrators", response.body
  end

  test "dashboard displays deposits section" do
    sign_in @admin
    get admin_root_path
    assert_match "Deposits", response.body
  end

  test "dashboard displays withdrawals section" do
    sign_in @admin
    get admin_root_path
    assert_match "Withdrawals", response.body
  end

  test "dashboard displays investments section" do
    sign_in @admin
    get admin_root_path
    assert_match "Investments", response.body
  end

  test "dashboard displays financial overview section" do
    sign_in @admin
    get admin_root_path
    assert_match "Financial Overview", response.body
    assert_match "Total BTC Available", response.body
    assert_match "Total Invested Capital", response.body
    assert_match "Total Profit Paid", response.body
    assert_match "Principal Returned", response.body
  end

  # --- metric accuracy ---

  test "dashboard displays correct total user count" do
    sign_in @admin
    get admin_root_path
    assert_match User.count.to_s, response.body
  end

  test "dashboard displays correct pending deposit count" do
    plan = create_investment_plan(position: 9901)
    Deposit.create!(
      user: @member, investment_plan: plan,
      amount_usd: plan.investment_amount_usd, btc_amount: 0.001,
      transaction_hash: "dashtest#{SecureRandom.hex(26)}",
      submitted_at: Time.current
    )
    sign_in @admin
    get admin_root_path
    pending_count = Deposit.where(status: :pending).count
    assert_match pending_count.to_s, response.body
  end

  test "dashboard displays financial totals" do
    sign_in @admin
    get admin_root_path
    assert_match "BTC", response.body
  end
end
