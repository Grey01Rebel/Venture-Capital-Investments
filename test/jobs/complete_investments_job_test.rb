# frozen_string_literal: true
require "test_helper"

class CompleteInvestmentsJobTest < ActiveSupport::TestCase
  def setup
    @admin = create_confirmed_user
    @admin.update!(role: :admin)
    @plan  = create_investment_plan(
      position:              2201,
      investment_amount_usd: 500.00,
      daily_return_rate:     0.80
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

  # --- completed investment processed successfully ---

  test "completes an eligible investment" do
    investment = build_investment("cij1", ends_at: 1.day.ago)

    CompleteInvestmentsJob.perform_now

    assert investment.reload.completed?
  end

  test "sets completed_at for an eligible investment" do
    investment = build_investment("cij2", ends_at: 1.day.ago)

    CompleteInvestmentsJob.perform_now

    assert_not_nil investment.reload.completed_at
  end

  test "returns principal to wallet for an eligible investment" do
    investment = build_investment("cij3", ends_at: 1.day.ago)
    wallet = investment.user.wallet
    original_balance = wallet.available_balance

    CompleteInvestmentsJob.perform_now

    wallet.reload
    assert_equal original_balance + investment.principal_amount, wallet.available_balance
  end

  test "does not complete an investment whose end date has not been reached" do
    investment = build_investment("cij4", ends_at: 1.day.from_now)

    CompleteInvestmentsJob.perform_now

    assert investment.reload.active?
  end

  test "does not process already completed investments" do
    investment = build_investment("cij5", ends_at: 1.day.ago)
    investment.update!(status: :completed, completed_at: Time.current)
    original_completed_at = investment.completed_at

    CompleteInvestmentsJob.perform_now

    assert_equal original_completed_at, investment.reload.completed_at
  end

  # --- find_each iteration path covered, multiple investments ---

  test "processes multiple eligible investments independently" do
    investment_one   = build_investment("cij6", ends_at: 1.day.ago)
    investment_two   = build_investment("cij7", ends_at: 2.days.ago)
    investment_three = build_investment("cij8", ends_at: 1.day.from_now)

    CompleteInvestmentsJob.perform_now

    assert investment_one.reload.completed?
    assert investment_two.reload.completed?
    assert investment_three.reload.active?
  end

  # --- one failure does not halt remaining investments ---

  test "continues processing remaining investments if one fails unexpectedly" do
    failing_investment    = build_investment("cij9", ends_at: 1.day.ago)
    succeeding_investment = build_investment("cij10", ends_at: 1.day.ago)

    original_method = CompleteInvestmentService.instance_method(:call)
    call_count = 0

    CompleteInvestmentService.define_method(:call) do
      call_count += 1
      raise StandardError, "simulated failure" if call_count == 1

      original_method.bind(self).call
    end

    assert_nothing_raised do
      CompleteInvestmentsJob.perform_now
    end

    succeeding_investment.reload
    assert succeeding_investment.completed? || succeeding_investment.active?
  ensure
    CompleteInvestmentService.define_method(:call, original_method)
  end

  test "skipped investment due to future end date does not halt batch" do
    skipped_investment    = build_investment("cij11", ends_at: 1.day.from_now)
    succeeding_investment = build_investment("cij12", ends_at: 1.day.ago)

    CompleteInvestmentsJob.perform_now

    assert skipped_investment.reload.active?
    assert succeeding_investment.reload.completed?
  end

  # --- logging: success ---

  test "logs success for a completed investment" do
    investment = build_investment("cij13", ends_at: 1.day.ago)

    log_output = capture_rails_logger do
      CompleteInvestmentsJob.perform_now
    end

    assert_match(/Completed investment #{investment.id}/, log_output)
  end

  # --- logging: expected failure / skip ---

  test "logs a warning when an investment is skipped due to future end date" do
    investment = build_investment("cij14", ends_at: 1.day.from_now)

    log_output = capture_rails_logger do
      CompleteInvestmentsJob.perform_now
    end

    assert_match(/Skipped investment #{investment.id}/, log_output)
    assert_match(/end date/, log_output)
  end

  # --- logging: unexpected exception ---

  test "logs an error when an investment fails unexpectedly" do
    investment = build_investment("cij15", ends_at: 1.day.ago)

    original_method = CompleteInvestmentService.instance_method(:call)
    CompleteInvestmentService.define_method(:call) { raise StandardError, "simulated failure" }

    log_output = capture_rails_logger do
      CompleteInvestmentsJob.perform_now
    end

    assert_match(/Error completing investment #{investment.id}/, log_output)
    assert_match(/simulated failure/, log_output)
  ensure
    CompleteInvestmentService.define_method(:call, original_method)
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
