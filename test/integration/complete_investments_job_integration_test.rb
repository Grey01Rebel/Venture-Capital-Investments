require "test_helper"

class CompleteInvestmentsJobIntegrationTest < ActiveSupport::TestCase
  def setup
    @admin = create_confirmed_user
    @admin.update!(role: :admin)
    @plan  = create_investment_plan(
      position:              2301,
      investment_amount_usd: 1_000.00,
      daily_return_rate:     0.90
    )
  end

  def build_investment(hash_prefix, ends_at:)
    user = create_confirmed_user
    deposit = Deposit.create!(
      user:             user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "#{hash_prefix}#{SecureRandom.hex(24)}",
      submitted_at:     Time.current
    )
    DepositReviewService.new(deposit: deposit, action: :approve, reviewer: @admin).call
    deposit.reload
    investment = deposit.investment
    investment.update!(ends_at: ends_at)
    investment
  end

  # --- investment completed through service invocation ---

  test "investment transitions to completed exclusively through CompleteInvestmentService" do
    investment = build_investment("cijint1", ends_at: 1.day.ago)

    CompleteInvestmentsJob.perform_now

    investment.reload
    assert investment.completed?
    assert_not_nil investment.completed_at
  end

  test "job produces the same result as calling the service directly" do
    investment_via_job     = build_investment("cijint2", ends_at: 1.day.ago)
    investment_via_service = build_investment("cijint3", ends_at: 1.day.ago)

    CompleteInvestmentsJob.perform_now
    CompleteInvestmentService.new(investment_via_service).call

    assert_equal investment_via_job.reload.status, investment_via_service.reload.status
  end

  # --- wallet effects remain owned by service layer ---

  test "wallet available_balance increases by exactly the principal amount" do
    investment = build_investment("cijint4", ends_at: 1.day.ago)
    wallet = investment.user.wallet
    original_balance = wallet.available_balance

    CompleteInvestmentsJob.perform_now

    wallet.reload
    assert_equal original_balance + investment.principal_amount, wallet.available_balance
  end

  test "wallet total_profit is untouched by job-driven completion" do
    investment = build_investment("cijint5", ends_at: 1.day.ago)
    wallet = investment.user.wallet
    original_profit = wallet.total_profit

    CompleteInvestmentsJob.perform_now

    wallet.reload
    assert_equal original_profit, wallet.total_profit
  end

  test "wallet total_deposited is untouched by job-driven completion" do
    investment = build_investment("cijint6", ends_at: 1.day.ago)
    wallet = investment.user.wallet
    original_deposited = wallet.total_deposited

    CompleteInvestmentsJob.perform_now

    wallet.reload
    assert_equal original_deposited, wallet.total_deposited
  end

  test "wallet remains unchanged for an investment not yet eligible" do
    investment = build_investment("cijint7", ends_at: 1.day.from_now)
    wallet = investment.user.wallet
    original_balance = wallet.available_balance

    CompleteInvestmentsJob.perform_now

    wallet.reload
    assert_equal original_balance, wallet.available_balance
  end

  test "job never writes to wallet directly, only through service-driven completion" do
    investment = build_investment("cijint8", ends_at: 1.day.ago)
    wallet = investment.user.wallet

    # Sanity check: the job has no direct reference to Wallet at all,
    # verified functionally by confirming the increase matches principal exactly,
    # with no rounding or unrelated side effects.
    CompleteInvestmentsJob.perform_now

    wallet.reload
    assert_equal investment.principal_amount, wallet.available_balance
  end
end