# frozen_string_literal: true
require "application_system_test_case"

class DashboardInvestmentOverviewTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      full_name:             "Dashboard Admin",
      email:                 "dash_admin@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @admin.confirm
    @admin.update!(role: :admin)

    @member = User.create!(
      full_name:             "Dashboard Investor",
      email:                 "dash_investor@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @member.confirm

    create_all_six_plans
    @plan = InvestmentPlan.find_by(name: "Starter")
  end

  def build_investment(hash_prefix)
    deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "#{hash_prefix}#{SecureRandom.hex(24)}",
      submitted_at:     Time.current
    )
    deposit.approve!(reviewer: @admin)
    deposit.reload
    deposit.investment
  end

  test "dashboard displays investment overview section" do
    login_as @member
    visit authenticated_root_path
    assert_text "Investment Overview"
    assert_text "Active Investments"
    assert_text "Completed Investments"
    assert_text "Total Invested Capital"
    assert_text "Total Profit Earned"
  end

  test "active investment count displayed correctly" do
    build_investment("dash1")
    build_investment("dash2")

    login_as @member
    visit authenticated_root_path

    within("[data-testid='active-investments-card']") do
      assert_text "2"
    end
  end

  test "completed investment count displayed correctly" do
    investment = build_investment("dash3")
    investment.update!(status: :completed)

    login_as @member
    visit authenticated_root_path

    within("[data-testid='completed-investments-card']") do
      assert_text "1"
    end
  end

  test "invested capital displayed correctly" do
    build_investment("dash4")
    build_investment("dash5")

    login_as @member
    visit authenticated_root_path

    assert_text "$1,000.00"
  end

  test "total profit earned displayed correctly" do
    investment = build_investment("dash6")
    ProfitRecord.create!(
      user:        @member,
      investment:  investment,
      amount:      4.00,
      profit_date: Date.current
    )
    ProfitRecord.create!(
      user:        @member,
      investment:  investment,
      amount:      4.00,
      profit_date: Date.current - 1
    )

    login_as @member
    visit authenticated_root_path

    assert_text "$8.00"
  end

  test "investment overview shows zero values for a new user with no investments" do
    login_as @member
    visit authenticated_root_path

    within("[data-testid='active-investments-card']") do
      assert_text "0"
    end
    within("[data-testid='completed-investments-card']") do
      assert_text "0"
    end
  end
end
