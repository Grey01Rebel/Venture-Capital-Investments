# frozen_string_literal: true
require "test_helper"

class InvestmentPerformanceTest < ActiveSupport::TestCase
  def setup
    @admin = create_confirmed_user
    @admin.update!(role: :admin)
    @user  = create_confirmed_user
    @plan  = create_investment_plan(
      position:              1901,
      investment_amount_usd: 500.00,
      daily_return_rate:     0.80
    )

    @deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "perf#{SecureRandom.hex(28)}",
      submitted_at:     Time.current
    )
    @deposit.approve!(reviewer: @admin)
    @deposit.reload
    @investment = @deposit.investment
  end

  def add_profit_record(date, amount = 4.00)
    ProfitRecord.create!(
      user:        @user,
      investment:  @investment,
      amount:      amount,
      profit_date: date
    )
  end

  # --- total_profit_earned ---

  test "total_profit_earned is zero with no profit records" do
    assert_equal 0, @investment.total_profit_earned
  end

  test "total_profit_earned sums all associated profit records" do
    add_profit_record(Date.current, 4.00)
    add_profit_record(Date.current - 1, 4.00)
    add_profit_record(Date.current - 2, 4.00)
    assert_equal 12.00, @investment.reload.total_profit_earned
  end

  test "total_profit_earned reflects varying profit amounts" do
    add_profit_record(Date.current, 4.00)
    add_profit_record(Date.current - 1, 3.50)
    assert_equal 7.50, @investment.reload.total_profit_earned
  end

  # --- days_paid ---

  test "days_paid is zero with no profit records" do
    assert_equal 0, @investment.days_paid
  end

  test "days_paid counts the number of profit records" do
    add_profit_record(Date.current)
    add_profit_record(Date.current - 1)
    assert_equal 2, @investment.reload.days_paid
  end

  test "days_paid does not exceed actual record count" do
    5.times { |i| add_profit_record(Date.current - i) }
    assert_equal 5, @investment.reload.days_paid
  end

  # --- remaining_days ---

  test "remaining_days equals duration_days when no profit has been paid" do
    assert_equal @investment.duration_days, @investment.remaining_days
  end

  test "remaining_days decreases as days_paid increases" do
    add_profit_record(Date.current)
    add_profit_record(Date.current - 1)
    assert_equal @investment.duration_days - 2, @investment.reload.remaining_days
  end

  test "remaining_days never goes negative" do
    # duration_days is 14; create more profit records than the duration
    20.times { |i| add_profit_record(Date.current - i) }
    assert_equal 0, @investment.reload.remaining_days
  end

  test "remaining_days is zero when days_paid equals duration_days exactly" do
    @investment.duration_days.times { |i| add_profit_record(Date.current - i) }
    assert_equal 0, @investment.reload.remaining_days
  end
end
