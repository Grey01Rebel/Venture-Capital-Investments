# frozen_string_literal: true
require "test_helper"

class UserInvestmentReportingTest < ActiveSupport::TestCase
  def setup
    @admin = create_confirmed_user
    @admin.update!(role: :admin)
    @user  = create_confirmed_user
    @plan  = create_investment_plan(
      position:              2001,
      investment_amount_usd: 500.00,
      daily_return_rate:     0.80
    )
  end

  def build_investment(hash_prefix)
    deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "#{hash_prefix}#{SecureRandom.hex(26)}",
      submitted_at:     Time.current
    )
    deposit.approve!(reviewer: @admin)
    deposit.reload
    deposit.investment
  end

  # --- active_investments_count ---

  test "active_investments_count is zero with no investments" do
    assert_equal 0, @user.active_investments_count
  end

  test "active_investments_count counts only active investments" do
    build_investment("uir1")
    build_investment("uir2")
    assert_equal 2, @user.active_investments_count
  end

  test "active_investments_count excludes completed investments" do
    active_investment    = build_investment("uir3")
    completed_investment = build_investment("uir4")
    completed_investment.update!(status: :completed)

    assert_equal 1, @user.active_investments_count
  end

  # --- completed_investments_count ---

  test "completed_investments_count is zero with no completed investments" do
    build_investment("uir5")
    assert_equal 0, @user.completed_investments_count
  end

  test "completed_investments_count counts only completed investments" do
    investment_one = build_investment("uir6")
    investment_two = build_investment("uir7")
    investment_one.update!(status: :completed)
    investment_two.update!(status: :completed)

    assert_equal 2, @user.completed_investments_count
  end

  test "completed_investments_count excludes active investments" do
    build_investment("uir8")
    completed = build_investment("uir9")
    completed.update!(status: :completed)

    assert_equal 1, @user.completed_investments_count
  end

  # --- total_invested_capital ---

  test "total_invested_capital is zero with no investments" do
    assert_equal 0, @user.total_invested_capital
  end

  test "total_invested_capital sums principal_amount across investments" do
    build_investment("uir10")
    build_investment("uir11")
    assert_equal 1000.00, @user.total_invested_capital
  end

  test "total_invested_capital includes both active and completed investments" do
    active    = build_investment("uir12")
    completed = build_investment("uir13")
    completed.update!(status: :completed)

    assert_equal 1000.00, @user.total_invested_capital
  end

  # --- total_profit_earned ---

  test "total_profit_earned is zero with no profit records" do
    build_investment("uir14")
    assert_equal 0, @user.total_profit_earned
  end

  test "total_profit_earned sums profit records across all investments" do
    investment_one = build_investment("uir15")
    investment_two = build_investment("uir16")

    ProfitRecord.create!(user: @user, investment: investment_one, amount: 4.00, profit_date: Date.current)
    ProfitRecord.create!(user: @user, investment: investment_two, amount: 8.00, profit_date: Date.current)

    assert_equal 12.00, @user.total_profit_earned
  end

  test "total_profit_earned reflects records across multiple dates" do
    investment = build_investment("uir17")

    ProfitRecord.create!(user: @user, investment: investment, amount: 4.00, profit_date: Date.current)
    ProfitRecord.create!(user: @user, investment: investment, amount: 4.00, profit_date: Date.current - 1)

    assert_equal 8.00, @user.total_profit_earned
  end
end
