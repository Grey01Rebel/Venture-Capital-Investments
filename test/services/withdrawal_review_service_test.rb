# frozen_string_literal: true
require "test_helper"

class WithdrawalReviewServiceTest < ActiveSupport::TestCase
  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @member = create_confirmed_user
    @member.wallet.update!(available_balance: 0.04000000)

    @withdrawal = Withdrawal.create!(
      user:         @member,
      amount:       0.01000000,
      btc_address:  "bc1qreviewtest",
      status:       :pending,
      requested_at: Time.current
    )
  end

  def call_service(action:, notes: nil)
    WithdrawalReviewService.new(
      withdrawal:  @withdrawal,
      action:      action,
      reviewer:    @admin,
      admin_notes: notes
    ).call
  end

  # --- approval path ---

  test "approves a pending withdrawal" do
    result = call_service(action: :approve)
    assert result.success?
    assert @withdrawal.reload.approved?
  end

  test "sets approved_at on approval" do
    call_service(action: :approve)
    assert_not_nil @withdrawal.reload.approved_at
  end

  test "sets reviewer on approval" do
    call_service(action: :approve)
    assert_equal @admin, @withdrawal.reload.reviewer
  end

  test "stores admin_notes on approval" do
    call_service(action: :approve, notes: "Verified identity")
    assert_equal "Verified identity", @withdrawal.reload.admin_notes
  end

  test "approval does NOT modify wallet available_balance" do
    original_balance = @member.wallet.available_balance
    call_service(action: :approve)
    @member.wallet.reload
    assert_equal original_balance, @member.wallet.available_balance
  end

  test "approval returns a successful result object" do
    result = call_service(action: :approve)
    assert result.success?
    assert_instance_of Withdrawal, result.withdrawal
    assert_nil result.error
  end

  # --- rejection path ---

  test "rejects a pending withdrawal" do
    result = call_service(action: :reject)
    assert result.success?
    assert @withdrawal.reload.rejected?
  end

  test "sets rejected_at on rejection" do
    call_service(action: :reject)
    assert_not_nil @withdrawal.reload.rejected_at
  end

  test "sets reviewer on rejection" do
    call_service(action: :reject)
    assert_equal @admin, @withdrawal.reload.reviewer
  end

  test "stores admin_notes on rejection" do
    call_service(action: :reject, notes: "Suspicious address")
    assert_equal "Suspicious address", @withdrawal.reload.admin_notes
  end

  test "rejection restores wallet available_balance" do
    call_service(action: :reject)
    @member.wallet.reload
    assert_equal 0.05000000, @member.wallet.available_balance
  end

  test "rejection returns a successful result object" do
    result = call_service(action: :reject)
    assert result.success?
    assert_instance_of Withdrawal, result.withdrawal
    assert_nil result.error
  end

  # --- audit logging ---

  test "creates an audit log entry on approval" do
    assert_difference "AuditLog.count", 1 do
      call_service(action: :approve)
    end

    log = AuditLog.last
    assert_equal "withdrawal.approved", log.action
    assert_equal @admin, log.actor
    assert_equal @withdrawal, log.subject
  end

  test "creates an audit log entry on rejection" do
    assert_difference "AuditLog.count", 1 do
      call_service(action: :reject)
    end

    log = AuditLog.last
    assert_equal "withdrawal.rejected", log.action
    assert_equal @admin, log.actor
    assert_equal @withdrawal, log.subject
  end

  test "records the given ip_address on the audit log entry" do
    WithdrawalReviewService.new(
      withdrawal: @withdrawal, action: :approve, reviewer: @admin, ip_address: "203.0.113.9"
    ).call

    assert_equal "203.0.113.9", AuditLog.last.ip_address
  end

  test "does not create an audit log entry when the withdrawal is not pending" do
    @withdrawal.update!(status: :approved, approved_at: Time.current, reviewer: @admin)

    assert_no_difference "AuditLog.count" do
      call_service(action: :approve)
    end
  end

  test "does not create an audit log entry if rejection wallet update fails" do
    original_method = Wallet.instance_method(:update!)
    Wallet.define_method(:update!) { |*args| raise ActiveRecord::RecordInvalid.new(self) }

    assert_no_difference "AuditLog.count" do
      call_service(action: :reject)
    end
  ensure
    Wallet.define_method(:update!, original_method)
  end

  # --- guard: not pending ---

  test "returns failure if withdrawal is already approved" do
    @withdrawal.update!(status: :approved, approved_at: Time.current, reviewer: @admin)
    result = call_service(action: :approve)
    assert_not result.success?
    assert_equal "Withdrawal is not pending.", result.error
  end

  test "returns failure if withdrawal is already rejected" do
    @withdrawal.update!(status: :rejected, rejected_at: Time.current, reviewer: @admin)
    result = call_service(action: :reject)
    assert_not result.success?
    assert_equal "Withdrawal is not pending.", result.error
  end

  test "wallet unchanged when withdrawal is already approved" do
    @withdrawal.update!(status: :approved, approved_at: Time.current, reviewer: @admin)
    original_balance = @member.wallet.available_balance
    call_service(action: :approve)
    @member.wallet.reload
    assert_equal original_balance, @member.wallet.available_balance
  end

  # --- guard: unknown action ---

  test "returns failure for an unknown action" do
    result = WithdrawalReviewService.new(
      withdrawal: @withdrawal, action: :payout, reviewer: @admin
    ).call
    assert_not result.success?
    assert_match "Unknown action", result.error
  end

  # --- rollback: rejection ---

  test "withdrawal remains pending if rejection wallet update fails" do
    original_method = Wallet.instance_method(:update!)
    Wallet.define_method(:update!) { |*args| raise ActiveRecord::RecordInvalid.new(self) }

    result = call_service(action: :reject)

    assert_not result.success?
    assert @withdrawal.reload.pending?
  ensure
    Wallet.define_method(:update!, original_method)
  end

  test "wallet balance unchanged if rejection transaction rolls back" do
    original_balance = @member.wallet.available_balance
    original_method  = Wallet.instance_method(:update!)
    Wallet.define_method(:update!) { |*args| raise ActiveRecord::RecordInvalid.new(self) }

    call_service(action: :reject)

    @member.wallet.reload
    assert_equal original_balance, @member.wallet.available_balance
  ensure
    Wallet.define_method(:update!, original_method)
  end

  # --- guard: missing wallet on rejection ---

  test "returns failure if wallet is missing on rejection" do
    @member.wallet.destroy
    result = call_service(action: :reject)
    assert_not result.success?
    assert_equal "User wallet not found.", result.error
  end

  test "withdrawal remains pending if wallet is missing on rejection" do
    @member.wallet.destroy
    call_service(action: :reject)
    assert @withdrawal.reload.pending?
  end
end
