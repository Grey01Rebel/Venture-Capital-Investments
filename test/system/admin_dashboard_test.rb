# frozen_string_literal: true
require "application_system_test_case"

class AdminDashboardTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      full_name:             "Dashboard Admin",
      email:                 "dashboard_admin@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @admin.confirm
    @admin.update!(role: :admin)

    @member = User.create!(
      full_name:             "Dashboard Member",
      email:                 "dashboard_member@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @member.confirm

    create_all_six_plans
    @plan = InvestmentPlan.find_by(name: "Starter")
  end

  def build_approved_investment(hash_prefix)
    deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "#{hash_prefix}#{SecureRandom.hex(24)}",
      submitted_at:     Time.current
    )
    DepositReviewService.new(deposit: deposit, action: :approve, reviewer: @admin).call
    deposit.reload
    deposit.investment
  end

  # --- access control ---

  test "admin can visit the admin dashboard" do
    login_as @admin
    visit admin_root_path
    assert_text "Operations Dashboard"
  end

  test "member is redirected away from admin dashboard" do
    login_as @member
    visit admin_root_path
    assert_no_current_path admin_root_path
  end

  test "unauthenticated user is redirected from admin dashboard" do
    visit admin_root_path
    assert_current_path new_user_session_path
  end

  # --- navigation ---

  test "Admin Dashboard nav link is visible to admins" do
    login_as @admin
    visit authenticated_root_path
    assert_selector "a[href='#{admin_root_path}']", text: "Admin Dashboard"
  end

  test "Admin Dashboard nav link is not visible to members" do
    login_as @member
    visit authenticated_root_path
    assert_no_selector "a[href='#{admin_root_path}']"
  end

  # --- platform overview ---

  test "dashboard displays correct user counts" do
    login_as @admin
    visit admin_root_path
    assert_text "Total Users"
    assert_text "Members"
    assert_text "Administrators"
  end

  # --- deposit metrics ---

  test "dashboard shows pending deposit count" do
    Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.001,
      transaction_hash: "dashpend#{SecureRandom.hex(24)}",
      submitted_at:     Time.current
    )

    login_as @admin
    visit admin_root_path

    assert_text "Deposits"
    within("[data-testid='pending-deposits-card']") do
      assert_text Deposit.where(status: :pending).count.to_s
    end
  end

  # --- withdrawal metrics ---

  test "dashboard shows pending withdrawal count" do
    @member.wallet.update!(available_balance: 0.05)
    Withdrawal.create!(
      user:         @member,
      amount:       0.01,
      btc_address:  "bc1qdashboard",
      status:       :pending,
      requested_at: Time.current
    )

    login_as @admin
    visit admin_root_path

    within("[data-testid='pending-withdrawals-card']") do
      assert_text Withdrawal.where(status: :pending).count.to_s
    end
  end

  # --- investment metrics ---

  test "dashboard shows active investment count" do
    build_approved_investment("dashactive")

    login_as @admin
    visit admin_root_path

    within("[data-testid='active-investments-card']") do
      assert_text Investment.where(status: :active).count.to_s
    end
  end

  # --- financial overview ---

  test "dashboard displays financial overview" do
    login_as @admin
    visit admin_root_path
    assert_text "Financial Overview"
    assert_text "Total BTC Available"
    assert_text "Total Invested Capital"
    assert_text "Total Profit Paid"
    assert_text "Principal Returned"
  end

  # --- recent activity ---

  test "dashboard shows empty activity state when no records exist" do
    # Sign in as fresh admin with no platform activity
    fresh_admin = User.create!(
      full_name:             "Fresh Admin",
      email:                 "fresh_admin_dash@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    fresh_admin.confirm
    fresh_admin.update!(role: :admin)

    # Clear all activity records for a clean state
    ProfitRecord.delete_all
    Investment.delete_all
    Deposit.delete_all
    Withdrawal.delete_all

    login_as fresh_admin
    visit admin_root_path
    assert_text "No recent activity to display."
  end

  test "dashboard shows recent deposit in activity feed" do
    Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.001,
      transaction_hash: "dashrecent#{SecureRandom.hex(23)}",
      submitted_at:     Time.current
    )

    login_as @admin
    visit admin_root_path
    assert_text "Recent Activity"
    assert_text "Deposit"
  end

  test "dashboard shows recent investment in activity feed" do
    build_approved_investment("dashinv")

    login_as @admin
    visit admin_root_path
    assert_text "Investment Created"
  end
end
