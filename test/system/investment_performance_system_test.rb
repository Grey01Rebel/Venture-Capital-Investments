# frozen_string_literal: true
require "application_system_test_case"

class InvestmentPerformanceSystemTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      full_name:             "Performance Admin",
      email:                 "perf_admin@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @admin.confirm
    @admin.update!(role: :admin)

    @member = User.create!(
      full_name:             "Performance Investor",
      email:                 "perf_investor@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @member.confirm

    create_all_six_plans
    @plan = InvestmentPlan.find_by(name: "Starter")

    @deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "sysperf#{SecureRandom.hex(24)}",
      submitted_at:     Time.current
    )
    @deposit.approve!(reviewer: @admin)
    @deposit.reload
    @investment = @deposit.investment
  end

  test "performance metrics render correctly for an active investment with no profit yet" do
    login_as @member
    visit investment_path(@investment)

    assert_text "Investment Performance"
    assert_text "Total Profit Earned"
    assert_text "$0.00"
    assert_text "Days Paid"
    assert_text "0"
    assert_text "Remaining Days"
    assert_text "14"
  end

  test "performance metrics render correctly with profit records present" do
    ProfitRecord.create!(
      user:        @member,
      investment:  @investment,
      amount:      4.00,
      profit_date: Date.current
    )
    ProfitRecord.create!(
      user:        @member,
      investment:  @investment,
      amount:      4.00,
      profit_date: Date.current - 1
    )

    login_as @member
    visit investment_path(@investment)

    assert_text "$8.00"
    assert_text "2"
    assert_text "12"
  end

  test "active investment displays Active status alongside performance metrics" do
    login_as @member
    visit investment_path(@investment)

    assert_text "Active"
    assert_text "Investment Performance"
  end

  test "completed investment displays Completed status alongside performance metrics" do
    14.times do |i|
      ProfitRecord.create!(
        user:        @member,
        investment:  @investment,
        amount:      4.00,
        profit_date: Date.current - i
      )
    end
    @investment.update!(status: :completed, ends_at: 1.day.ago, completed_at: Time.current)

    login_as @member
    visit investment_path(@investment)

    assert_text "Completed"
    assert_text "$56.00"
    assert_text "Remaining Days"
  end

  test "term progress indicator is present on the show page" do
    login_as @member
    visit investment_path(@investment)
    assert_text "Term Progress"
    assert_selector "div.bg-amber-400.h-2"
  end
end
