# frozen_string_literal: true
require "test_helper"

class GenerateDailyProfitServiceTest < ActiveSupport::TestCase
  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @user   = create_confirmed_user
    @plan   = create_investment_plan(
      position:              1501,
      investment_amount_usd: 500.00,
      daily_return_rate:     0.80
    )

    @deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "gdp#{SecureRandom.hex(30)}",
      submitted_at:     Time.current
    )
    DepositReviewService.new(deposit: @deposit, action: :approve, reviewer: @admin).call
    @deposit.reload
    @investment = @deposit.investment
    @wallet     = @user.wallet
    @profit_date = Date.current
  end

  def call_service(date: @profit_date)
    GenerateDailyProfitService.new(@investment, date).call
  end

  # --- Successful generation ---

  test "creates a profit record on success" do
    assert_difference "ProfitRecord.count", 1 do
      call_service
    end
  end

  test "profit record has correct amount" do
    result = call_service
    assert_equal 4.00, result.profit_record.amount
  end

  test "profit record is associated with correct investment and user" do
    result = call_service
    assert_equal @investment, result.profit_record.investment
    assert_equal @user, result.profit_record.user
  end

  test "profit record has correct profit_date" do
    result = call_service
    assert_equal @profit_date, result.profit_record.profit_date
  end

  test "updates wallet available_balance" do
    original_balance = @wallet.available_balance
    call_service
    @wallet.reload
    assert_equal original_balance + 4.00, @wallet.available_balance
  end

  test "updates wallet total_profit" do
    original_profit = @wallet.total_profit
    call_service
    @wallet.reload
    assert_equal original_profit + 4.00, @wallet.total_profit
  end

  test "returns a successful result object" do
    result = call_service
    assert result.success?
    assert_not_nil result.profit_record
    assert_nil result.error
  end

  # --- Idempotency ---

  test "second execution for same date creates no new profit record" do
    call_service
    assert_no_difference "ProfitRecord.count" do
      call_service
    end
  end

  test "second execution for same date returns failure" do
    call_service
    result = call_service
    assert_not result.success?
    assert_equal "Profit has already been generated for this date.", result.error
  end

  test "wallet remains unchanged on second execution" do
    call_service
    @wallet.reload
    balance_after_first = @wallet.available_balance
    profit_after_first   = @wallet.total_profit

    call_service
    @wallet.reload
    assert_equal balance_after_first, @wallet.available_balance
    assert_equal profit_after_first,  @wallet.total_profit
  end

  test "allows profit generation for the same investment on a different date" do
    call_service(date: @profit_date)
    assert_difference "ProfitRecord.count", 1 do
      call_service(date: @profit_date + 1)
    end
  end

  # --- Inactive investment ---

  test "returns failure for an inactive investment" do
    @investment.update!(status: :completed)
    result = call_service
    assert_not result.success?
    assert_equal "Investment is not active.", result.error
  end

  test "creates nothing for an inactive investment" do
    @investment.update!(status: :completed)
    assert_no_difference "ProfitRecord.count" do
      call_service
    end
  end

  test "wallet unchanged for an inactive investment" do
    @investment.update!(status: :completed)
    original_balance = @wallet.available_balance
    call_service
    @wallet.reload
    assert_equal original_balance, @wallet.available_balance
  end

  # --- Missing wallet ---

  test "returns failure when wallet is missing" do
    @wallet.destroy
    result = call_service
    assert_not result.success?
    assert_equal "User wallet not found.", result.error
  end

  test "creates nothing when wallet is missing" do
    @wallet.destroy
    assert_no_difference "ProfitRecord.count" do
      call_service
    end
  end

  # --- Transaction rollback ---

  test "wallet remains unchanged if profit record creation fails" do
    # Force a failure by pre-creating a conflicting profit record
    # then bypassing the service's own idempotency check via direct DB manipulation
    # is not possible cleanly — instead we simulate a validation failure
    # by stubbing amount calculation to produce an invalid value.
    original_balance = @wallet.available_balance
    original_profit  = @wallet.total_profit

    @investment.update_column(:daily_return_rate, 0)

    result = GenerateDailyProfitService.new(@investment, @profit_date).call

    assert_not result.success?
    @wallet.reload
    assert_equal original_balance, @wallet.available_balance
    assert_equal original_profit,  @wallet.total_profit
  end

  test "no profit record created if transaction rolls back" do
    @investment.update_column(:daily_return_rate, 0)
    assert_no_difference "ProfitRecord.count" do
      GenerateDailyProfitService.new(@investment, @profit_date).call
    end
  end

  # --- Calculation ---

  test "calculates daily profit correctly using simple interest formula" do
    # $500 principal * 0.80% = $4.00
    result = call_service
    assert_equal 4.00, result.profit_record.amount
  end

  test "calculates daily profit correctly for a different plan" do
    gold_plan = create_investment_plan(
      position:              1502,
      investment_amount_usd: 3_000.00,
      daily_return_rate:     1.20
    )
    gold_deposit = Deposit.create!(
      user:             @user,
      investment_plan:  gold_plan,
      amount_usd:       gold_plan.investment_amount_usd,
      btc_amount:       0.05000000,
      transaction_hash: "gdp2#{SecureRandom.hex(28)}",
      submitted_at:     Time.current
    )
    DepositReviewService.new(deposit: gold_deposit, action: :approve, reviewer: @admin).call
    gold_deposit.reload
    gold_investment = gold_deposit.investment

    result = GenerateDailyProfitService.new(gold_investment, @profit_date).call
    # $3000 * 1.20% = $36.00
    assert_equal 36.00, result.profit_record.amount
  end

  # --- Result object shape ---

  test "success result has profit_record and nil error" do
    result = call_service
    assert result.success?
    assert_instance_of ProfitRecord, result.profit_record
    assert_nil result.error
  end

  test "failure result has nil profit_record and an error message" do
    @investment.update!(status: :completed)
    result = call_service
    assert_not result.success?
    assert_nil result.profit_record
    assert_kind_of String, result.error
  end
end
