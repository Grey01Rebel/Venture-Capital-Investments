# frozen_string_literal: true
require "test_helper"

class GenerateDailyProfitsJobTest < ActiveSupport::TestCase
  def setup
    @admin = create_confirmed_user
    @admin.update!(role: :admin)
    @plan  = create_investment_plan(
      position:              1601,
      investment_amount_usd: 500.00,
      daily_return_rate:     0.80
    )
    @profit_date = Date.current
  end

  def build_active_investment(hash_prefix)
    user = create_confirmed_user
    deposit = Deposit.create!(
      user:             user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "#{hash_prefix}#{SecureRandom.hex(26)}",
      submitted_at:     Time.current
    )
    DepositReviewService.new(deposit: deposit, action: :approve, reviewer: @admin).call
    deposit.reload
    deposit.investment
  end

  # --- Active investments processed ---

  test "calls GenerateDailyProfitService once per active investment" do
    investment = build_active_investment("job1")

    assert_difference "ProfitRecord.count", 1 do
      GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)
    end

    assert ProfitRecord.exists?(investment: investment, profit_date: @profit_date)
  end

  test "creates a profit record with correct amount for an active investment" do
    investment = build_active_investment("job2")
    GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)
    record = ProfitRecord.find_by(investment: investment, profit_date: @profit_date)
    assert_equal 4.00, record.amount
  end

  test "updates wallet for an active investment" do
    investment = build_active_investment("job3")
    wallet = investment.user.wallet
    original_balance = wallet.available_balance

    GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)

    wallet.reload
    assert_equal original_balance + 4.00, wallet.available_balance
  end

  # --- Completed investments skipped ---

  test "does not process completed investments" do
    investment = build_active_investment("job4")
    investment.update!(status: :completed)

    assert_no_difference "ProfitRecord.count" do
      GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)
    end
  end

  test "completed investment wallet remains unchanged" do
    investment = build_active_investment("job5")
    investment.update!(status: :completed)
    wallet = investment.user.wallet
    original_balance = wallet.available_balance

    GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)

    wallet.reload
    assert_equal original_balance, wallet.available_balance
  end

  # --- Multiple investments ---

  test "processes each active investment independently" do
    investment_one   = build_active_investment("job6")
    investment_two   = build_active_investment("job7")
    investment_three = build_active_investment("job8")

    assert_difference "ProfitRecord.count", 3 do
      GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)
    end

    [investment_one, investment_two, investment_three].each do |investment|
      assert ProfitRecord.exists?(investment: investment, profit_date: @profit_date)
    end
  end

  test "only processes active investments among a mix of active and completed" do
    active_investment    = build_active_investment("job9")
    completed_investment = build_active_investment("job10")
    completed_investment.update!(status: :completed)

    assert_difference "ProfitRecord.count", 1 do
      GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)
    end

    assert ProfitRecord.exists?(investment: active_investment, profit_date: @profit_date)
    assert_not ProfitRecord.exists?(investment: completed_investment, profit_date: @profit_date)
  end

  # --- Service failure does not stop the batch ---

  test "continues processing remaining investments if one fails" do
    failing_investment   = build_active_investment("job11")
    succeeding_investment = build_active_investment("job12")

    # Force a failure on the first investment by pre-creating its profit record,
    # triggering the service's duplicate-prevention failure path.
    ProfitRecord.create!(
      user:        failing_investment.user,
      investment:  failing_investment,
      amount:      4.00,
      profit_date: @profit_date
    )

    assert_difference "ProfitRecord.count", 1 do
      GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)
    end

    assert ProfitRecord.exists?(investment: succeeding_investment, profit_date: @profit_date)
  end

  test "job completes without raising when one investment errors unexpectedly" do
    investment = build_active_investment("job13")

    original_method = GenerateDailyProfitService.instance_method(:call)
    GenerateDailyProfitService.define_method(:call) { raise StandardError, "simulated failure" }

    assert_nothing_raised do
      GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)
    end
  ensure
    GenerateDailyProfitService.define_method(:call, original_method)
  end

  # --- Logging ---

  test "logs success for a generated profit record" do
    investment = build_active_investment("job14")

    log_output = capture_rails_logger do
      GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)
    end

    assert_match(/Profit generated/, log_output)
    assert_match(/investment_id=#{investment.id}/, log_output)
  end

  test "logs a warning when profit generation is skipped" do
    investment = build_active_investment("job15")
    ProfitRecord.create!(
      user:        investment.user,
      investment:  investment,
      amount:      4.00,
      profit_date: @profit_date
    )

    log_output = capture_rails_logger do
      GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)
    end

    assert_match(/Profit skipped/, log_output)
    assert_match(/investment_id=#{investment.id}/, log_output)
  end

  test "logs an error when an investment fails unexpectedly" do
    investment = build_active_investment("job16")

    original_method = GenerateDailyProfitService.instance_method(:call)
    GenerateDailyProfitService.define_method(:call) { raise StandardError, "simulated failure" }

    log_output = capture_rails_logger do
      GenerateDailyProfitsJob.perform_now(profit_date: @profit_date)
    end

    assert_match(/Unexpected failure/, log_output)
    assert_match(/investment_id=#{investment.id}/, log_output)
  ensure
    GenerateDailyProfitService.define_method(:call, original_method)
  end

  private

  def capture_rails_logger
    original_logger = Rails.logger
    io = StringIO.new
    Rails.logger = Logger.new(io)
    yield
    io.string
  ensure
    Rails.logger = original_logger
  end
end
