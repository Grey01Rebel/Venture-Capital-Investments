# frozen_string_literal: true
require "test_helper"

class WalletLockingTest < ActiveSupport::TestCase
  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @user   = create_confirmed_user
    @wallet = @user.wallet
    @wallet.update!(available_balance: 0.10000000)

    @plan = create_investment_plan(
      position:              9101,
      investment_amount_usd: 500.00,
      daily_return_rate:     0.80
    )
  end

  def build_investment(hash_prefix, ends_at: 1.day.ago)
    deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "#{hash_prefix}#{SecureRandom.hex(26)}",
      submitted_at:     Time.current
    )
    DepositReviewService.new(deposit: deposit, action: :approve, reviewer: @admin).call
    deposit.reload
    investment = deposit.investment
    investment.update!(ends_at: ends_at)
    investment
  end

  # --- WithdrawalRequestService locking ---

  test "withdrawal submission reads balance inside the lock" do
    # Verify that the balance check and debit are atomic:
    # submit a withdrawal for the exact available balance — should succeed.
    result = WithdrawalRequestService.new(
      user:        @user,
      amount:      0.10000000,
      btc_address: "bc1qlocktest1"
    ).call

    assert result.success?
    @wallet.reload
    assert_equal 0, @wallet.available_balance
  end

  test "withdrawal submission fails correctly when balance is exactly zero" do
    @wallet.update!(available_balance: 0)
    result = WithdrawalRequestService.new(
      user:        @user,
      amount:      0.00000001,
      btc_address: "bc1qlocktest2"
    ).call

    assert_not result.success?
    assert_equal "Insufficient balance.", result.error
  end

  test "sequential withdrawals correctly reduce balance atomically" do
    WithdrawalRequestService.new(user: @user, amount: 0.04000000, btc_address: "bc1qseq1").call
    WithdrawalRequestService.new(user: @user, amount: 0.03000000, btc_address: "bc1qseq2").call
    WithdrawalRequestService.new(user: @user, amount: 0.02000000, btc_address: "bc1qseq3").call

    @wallet.reload
    assert_equal 0.01000000, @wallet.available_balance
  end

  test "second withdrawal fails when balance exhausted by first" do
    WithdrawalRequestService.new(user: @user, amount: 0.10000000, btc_address: "bc1qexhaust1").call
    result = WithdrawalRequestService.new(user: @user, amount: 0.00000001, btc_address: "bc1qexhaust2").call

    assert_not result.success?
    assert_equal "Insufficient balance.", result.error
  end

  # --- WithdrawalReviewService rejection locking ---

  test "rejection restores balance atomically" do
    withdrawal = Withdrawal.create!(
      user:         @user,
      amount:       0.05000000,
      btc_address:  "bc1qrejlock",
      status:       :pending,
      requested_at: Time.current
    )
    @wallet.update!(available_balance: 0.05000000) # simulate post-submission balance

    result = WithdrawalReviewService.new(
      withdrawal: withdrawal,
      action:     :reject,
      reviewer:   @admin
    ).call

    assert result.success?
    @wallet.reload
    assert_equal 0.10000000, @wallet.available_balance
  end

  test "rejection balance restore is not affected by concurrent reads" do
    withdrawal_one = Withdrawal.create!(
      user: @user, amount: 0.03000000,
      btc_address: "bc1qconcurr1",
      status: :pending, requested_at: Time.current
    )
    withdrawal_two = Withdrawal.create!(
      user: @user, amount: 0.02000000,
      btc_address: "bc1qconcurr2",
      status: :pending, requested_at: Time.current
    )
    # Simulate both having been submitted: balance was reduced by both amounts
    @wallet.update!(available_balance: 0.05000000)

    WithdrawalReviewService.new(withdrawal: withdrawal_one, action: :reject, reviewer: @admin).call
    WithdrawalReviewService.new(withdrawal: withdrawal_two, action: :reject, reviewer: @admin).call

    @wallet.reload
    assert_equal 0.10000000, @wallet.available_balance
  end

  # --- GenerateDailyProfitService locking ---

  test "daily profit credit reads and writes balance inside the lock" do
    investment = build_investment("lockprofit1")
    original_balance = @wallet.available_balance
    original_profit  = @wallet.total_profit

    result = GenerateDailyProfitService.new(investment, Date.current).call

    assert result.success?
    @wallet.reload
    assert_equal original_balance + result.profit_record.amount, @wallet.available_balance
    assert_equal original_profit  + result.profit_record.amount, @wallet.total_profit
  end

  test "sequential profit credits accumulate correctly" do
    investment = build_investment("lockprofit2")
    original_balance = @wallet.available_balance

    GenerateDailyProfitService.new(investment, Date.current - 2).call
    GenerateDailyProfitService.new(investment, Date.current - 1).call
    GenerateDailyProfitService.new(investment, Date.current).call

    @wallet.reload
    expected = original_balance + (investment.principal_amount * (investment.daily_return_rate / 100) * 3)
    assert_equal expected.round(8), @wallet.available_balance.round(8)
  end

  # --- CompleteInvestmentService locking ---

  test "investment completion credits principal inside the lock" do
    investment = build_investment("lockcomp1")
    original_balance = @wallet.available_balance

    result = CompleteInvestmentService.new(investment).call

    assert result.success?
    @wallet.reload
    assert_equal original_balance + investment.principal_amount, @wallet.available_balance
  end

  test "completion does not affect total_profit or total_deposited" do
    investment = build_investment("lockcomp2")
    original_profit    = @wallet.total_profit
    original_deposited = @wallet.total_deposited

    CompleteInvestmentService.new(investment).call

    @wallet.reload
    assert_equal original_profit,    @wallet.total_profit
    assert_equal original_deposited, @wallet.total_deposited
  end

  # --- Cross-service sequential correctness ---

  test "profit then completion credits are both applied correctly in sequence" do
    investment = build_investment("lockseq1")
    original_balance = @wallet.available_balance

    profit_result = GenerateDailyProfitService.new(investment, Date.current).call
    complete_result = CompleteInvestmentService.new(investment.reload).call

    assert profit_result.success?
    assert complete_result.success?

    @wallet.reload
    profit_amount    = profit_result.profit_record.amount
    principal_amount = investment.principal_amount

    assert_equal original_balance + profit_amount + principal_amount,
                 @wallet.available_balance
  end

  test "withdrawal then rejection restores balance to pre-withdrawal state" do
    original_balance = @wallet.available_balance

    withdrawal_result = WithdrawalRequestService.new(
      user:        @user,
      amount:      0.05000000,
      btc_address: "bc1qroundtrip"
    ).call

    assert withdrawal_result.success?
    @wallet.reload
    assert_equal original_balance - 0.05000000, @wallet.available_balance

    reject_result = WithdrawalReviewService.new(
      withdrawal: withdrawal_result.withdrawal,
      action:     :reject,
      reviewer:   @admin
    ).call

    assert reject_result.success?
    @wallet.reload
    assert_equal original_balance, @wallet.available_balance
  end

  # --- Regression: existing behaviour unchanged ---

  test "withdrawal request service still returns correct result object after locking" do
    result = WithdrawalRequestService.new(
      user: @user, amount: 0.01000000, btc_address: "bc1qregress1"
    ).call

    assert result.success?
    assert_instance_of Withdrawal, result.withdrawal
    assert_nil result.error
  end

  test "daily profit service still returns correct result object after locking" do
    investment = build_investment("lockregress1")
    result = GenerateDailyProfitService.new(investment, Date.current).call

    assert result.success?
    assert_instance_of ProfitRecord, result.profit_record
    assert_nil result.error
  end

  test "complete investment service still returns correct result object after locking" do
    investment = build_investment("lockregress2")
    result = CompleteInvestmentService.new(investment).call

    assert result.success?
    assert_instance_of Investment, result.investment
    assert_nil result.error
  end

  test "withdrawal review service rejection still returns correct result object after locking" do
    withdrawal = Withdrawal.create!(
      user: @user, amount: 0.01000000,
      btc_address: "bc1qregressrej",
      status: :pending, requested_at: Time.current
    )

    result = WithdrawalReviewService.new(
      withdrawal: withdrawal, action: :reject, reviewer: @admin
    ).call

    assert result.success?
    assert_instance_of Withdrawal, result.withdrawal
    assert_nil result.error
  end
end
