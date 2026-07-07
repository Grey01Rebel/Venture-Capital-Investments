require "test_helper"

class CompleteInvestmentServiceTest < ActiveSupport::TestCase
  def setup
    @admin = create_confirmed_user
    @admin.update!(role: :admin)
    @user  = create_confirmed_user
    @plan  = create_investment_plan(
      position:              1701,
      investment_amount_usd: 500.00,
      daily_return_rate:     0.80
    )
    @wallet = @user.wallet
  end

  def build_investment(ends_at:, hash_prefix: "cis")
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

  def call_service(investment)
    CompleteInvestmentService.new(investment).call
  end

  # --- Successful completion ---

  test "marks investment as completed on success" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis1")
    call_service(investment)
    investment.reload
    assert investment.completed?
  end

  test "sets completed_at on success" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis2")
    call_service(investment)
    investment.reload
    assert_not_nil investment.completed_at
  end

  test "returns principal to wallet available_balance" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis3")
    original_balance = @wallet.available_balance

    call_service(investment)

    @wallet.reload
    assert_equal original_balance + investment.principal_amount, @wallet.available_balance
  end

  test "does not change total_profit" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis4")
    original_profit = @wallet.total_profit

    call_service(investment)

    @wallet.reload
    assert_equal original_profit, @wallet.total_profit
  end

  test "does not change total_deposited" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis5")
    original_deposited = @wallet.total_deposited

    call_service(investment)

    @wallet.reload
    assert_equal original_deposited, @wallet.total_deposited
  end

  test "does not change total_withdrawn" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis6")
    original_withdrawn = @wallet.total_withdrawn

    call_service(investment)

    @wallet.reload
    assert_equal original_withdrawn, @wallet.total_withdrawn
  end

  test "returns a successful result object" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis7")
    result = call_service(investment)
    assert result.success?
    assert_equal investment, result.investment
    assert_nil result.error
  end

  test "succeeds when ends_at is exactly now" do
    investment = build_investment(ends_at: Time.current, hash_prefix: "cis8")
    result = call_service(investment)
    assert result.success?
  end

  # --- Already completed investment ---

  test "returns failure for an already completed investment" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis9")
    investment.update!(status: :completed, completed_at: Time.current)

    result = call_service(investment)
    assert_not result.success?
    assert_equal "Investment is already completed.", result.error
  end

  test "wallet unchanged for an already completed investment" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis10")
    investment.update!(status: :completed, completed_at: Time.current)
    original_balance = @wallet.available_balance

    call_service(investment)

    @wallet.reload
    assert_equal original_balance, @wallet.available_balance
  end

  # --- Future end date ---

  test "returns failure when ends_at is still in the future" do
    investment = build_investment(ends_at: 1.day.from_now, hash_prefix: "cis11")
    result = call_service(investment)
    assert_not result.success?
    assert_equal "Investment has not yet reached its end date.", result.error
  end

  test "wallet unchanged when ends_at is in the future" do
    investment = build_investment(ends_at: 1.day.from_now, hash_prefix: "cis12")
    original_balance = @wallet.available_balance

    call_service(investment)

    @wallet.reload
    assert_equal original_balance, @wallet.available_balance
  end

  test "investment remains active when ends_at is in the future" do
    investment = build_investment(ends_at: 1.day.from_now, hash_prefix: "cis13")
    call_service(investment)
    investment.reload
    assert investment.active?
  end

  # --- Missing wallet ---

  test "returns failure when wallet is missing" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis14")
    @wallet.destroy

    result = call_service(investment)
    assert_not result.success?
    assert_equal "User wallet not found.", result.error
  end

  test "investment remains active when wallet is missing" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis15")
    @wallet.destroy

    call_service(investment)

    investment.reload
    assert investment.active?
  end

  # --- Transaction rollback ---

  test "wallet remains unchanged if investment update fails" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis16")
    original_balance = @wallet.available_balance

    # Force the investment update to fail by corrupting a required field
    # in a way that fails model validation during the transaction.
    investment.define_singleton_method(:update!) do |*args|
      raise ActiveRecord::RecordInvalid.new(self)
    end

    result = CompleteInvestmentService.new(investment).call

    assert_not result.success?
    @wallet.reload
    assert_equal original_balance, @wallet.available_balance
  end

  test "investment remains active if transaction rolls back" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis17")

    investment.define_singleton_method(:update!) do |*args|
      raise ActiveRecord::RecordInvalid.new(self)
    end

    CompleteInvestmentService.new(investment).call

    assert_equal "active", investment.reload.status
  end

  # --- Result object shape ---

  test "success result has investment and nil error" do
    investment = build_investment(ends_at: 1.day.ago, hash_prefix: "cis18")
    result = call_service(investment)
    assert result.success?
    assert_instance_of Investment, result.investment
    assert_nil result.error
  end

  test "failure result has nil investment and an error message" do
    investment = build_investment(ends_at: 1.day.from_now, hash_prefix: "cis19")
    result = call_service(investment)
    assert_not result.success?
    assert_nil result.investment
    assert_kind_of String, result.error
  end
end