# frozen_string_literal: true
require "test_helper"

class DepositReviewServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @member = create_confirmed_user
    @plan   = create_investment_plan(position: 1201)

    @deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "revsvc#{SecureRandom.hex(28)}",
      submitted_at:     Time.current
    )
  end

  def call_service(action:, notes: nil)
    DepositReviewService.new(
      deposit:     @deposit,
      action:      action,
      reviewer:    @admin,
      admin_notes: notes
    ).call
  end

  # --- approval path ---

  test "approves a pending deposit" do
    result = call_service(action: :approve)
    assert result.success?
    assert @deposit.reload.approved?
  end

  test "sets approved_at on approval" do
    call_service(action: :approve)
    assert_not_nil @deposit.reload.approved_at
  end

  test "sets reviewer on approval" do
    call_service(action: :approve)
    assert_equal @admin, @deposit.reload.reviewer
  end

  test "stores admin_notes on approval" do
    call_service(action: :approve, notes: "Verified on chain.")
    assert_equal "Verified on chain.", @deposit.reload.admin_notes
  end

  test "admin_notes is nil when not provided on approval" do
    call_service(action: :approve)
    assert_nil @deposit.reload.admin_notes
  end

  test "creates an investment on successful approval" do
    assert_difference "Investment.count", 1 do
      call_service(action: :approve)
    end
    assert @deposit.reload.investment.present?
  end

  test "investment is associated with the correct deposit" do
    call_service(action: :approve)
    assert_equal @deposit, @deposit.reload.investment.deposit
  end

  test "enqueues an approval notification email on success" do
    assert_enqueued_email_with DepositMailer, :approved, args: [@deposit] do
      call_service(action: :approve)
    end
  end

  # --- rejection path ---

  test "rejects a pending deposit" do
    result = call_service(action: :reject)
    assert result.success?
    assert @deposit.reload.rejected?
  end

  test "sets rejected_at on rejection" do
    call_service(action: :reject)
    assert_not_nil @deposit.reload.rejected_at
  end

  test "sets reviewer on rejection" do
    call_service(action: :reject)
    assert_equal @admin, @deposit.reload.reviewer
  end

  test "stores admin_notes on rejection" do
    call_service(action: :reject, notes: "Hash not found.")
    assert_equal "Hash not found.", @deposit.reload.admin_notes
  end

  test "does not create an investment on rejection" do
    assert_no_difference "Investment.count" do
      call_service(action: :reject)
    end
  end

  test "enqueues a rejection notification email on success" do
    assert_enqueued_email_with DepositMailer, :rejected, args: [@deposit] do
      call_service(action: :reject)
    end
  end

  # --- audit logging ---

  test "creates an audit log entry on approval" do
    assert_difference "AuditLog.count", 1 do
      call_service(action: :approve)
    end

    log = AuditLog.last
    assert_equal "deposit.approved", log.action
    assert_equal @admin, log.actor
    assert_equal @deposit, log.subject
  end

  test "creates an audit log entry on rejection" do
    assert_difference "AuditLog.count", 1 do
      call_service(action: :reject)
    end

    log = AuditLog.last
    assert_equal "deposit.rejected", log.action
    assert_equal @admin, log.actor
    assert_equal @deposit, log.subject
  end

  test "records the given ip_address on the audit log entry" do
    DepositReviewService.new(
      deposit: @deposit, action: :approve, reviewer: @admin, ip_address: "203.0.113.7"
    ).call

    assert_equal "203.0.113.7", AuditLog.last.ip_address
  end

  test "does not create an audit log entry when approval fails" do
    call_service(action: :approve)

    assert_no_difference "AuditLog.count" do
      call_service(action: :approve)
    end
  end

  # --- guards ---

  test "returns failure when approving an already approved deposit" do
    call_service(action: :approve)
    result = call_service(action: :approve)
    assert_not result.success?
    assert_equal "Deposit is not pending.", result.error
  end

  test "returns failure when approving a rejected deposit" do
    call_service(action: :reject)
    result = call_service(action: :approve)
    assert_not result.success?
  end

  test "returns failure when rejecting an already rejected deposit" do
    call_service(action: :reject)
    result = call_service(action: :reject)
    assert_not result.success?
    assert_equal "Deposit is not pending.", result.error
  end

  test "returns failure when rejecting an approved deposit" do
    call_service(action: :approve)
    result = call_service(action: :reject)
    assert_not result.success?
  end

  # --- atomicity ---

  test "deposit remains pending if investment creation fails during approval" do
    # Create a conflicting investment ahead of time so InvestmentCreationService
    # fails its "already has an investment" guard once the deposit is approved.
    Investment.create!(
      user:              @member,
      deposit:           @deposit,
      investment_plan:   @plan,
      principal_amount:  500.00,
      daily_return_rate: 0.80,
      duration_days:     14,
      started_at:        Time.current,
      ends_at:           14.days.from_now
    )

    result = call_service(action: :approve)

    assert_not result.success?
    assert @deposit.reload.pending?
  end

  test "does not enqueue an approval email when investment creation fails" do
    Investment.create!(
      user:              @member,
      deposit:           @deposit,
      investment_plan:   @plan,
      principal_amount:  500.00,
      daily_return_rate: 0.80,
      duration_days:     14,
      started_at:        Time.current,
      ends_at:           14.days.from_now
    )

    assert_no_enqueued_emails do
      call_service(action: :approve)
    end
  end
end
