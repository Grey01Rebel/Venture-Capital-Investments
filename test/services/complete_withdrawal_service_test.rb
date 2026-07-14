# frozen_string_literal: true
require "test_helper"

class CompleteWithdrawalServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @member = create_confirmed_user
    @member.wallet.update!(available_balance: 0.04000000)

    @withdrawal = Withdrawal.create!(
      user:         @member,
      amount:       0.01000000,
      btc_address:  "bc1qcomplete",
      status:       :approved,
      requested_at: Time.current,
      approved_at:  Time.current,
      reviewed_by_id: @admin.id
    )
  end

  def call_service(hash: "abc123txhash#{SecureRandom.hex(8)}")
    CompleteWithdrawalService.new(
      withdrawal:       @withdrawal,
      transaction_hash: hash
    ).call
  end

  # --- successful completion ---

  test "marks withdrawal as completed" do
    result = call_service
    assert result.success?
    assert @withdrawal.reload.completed?
  end

  test "sets completed_at" do
    call_service
    assert_not_nil @withdrawal.reload.completed_at
  end

  test "stores transaction_hash" do
    call_service(hash: "txhash_abc123")
    assert_equal "txhash_abc123", @withdrawal.reload.transaction_hash
  end

  test "does not modify wallet available_balance" do
    original_balance = @member.wallet.available_balance
    call_service
    @member.wallet.reload
    assert_equal original_balance, @member.wallet.available_balance
  end

  test "preserves existing reviewer" do
    call_service
    assert_equal @admin, @withdrawal.reload.reviewer
  end

  test "preserves existing admin_notes" do
    @withdrawal.update!(admin_notes: "Verified identity")
    call_service
    assert_equal "Verified identity", @withdrawal.reload.admin_notes
  end

  test "returns a successful result object" do
    result = call_service
    assert result.success?
    assert_instance_of Withdrawal, result.withdrawal
    assert_nil result.error
  end

  test "enqueues a completion notification email on success" do
    assert_enqueued_email_with WithdrawalMailer, :completed, args: [@withdrawal] do
      call_service
    end
  end

  # --- transaction_hash validation ---

  test "returns failure when transaction_hash is blank" do
    result = call_service(hash: "")
    assert_not result.success?
    assert_equal "Transaction hash is required.", result.error
  end

  test "returns failure when transaction_hash is whitespace only" do
    result = call_service(hash: "   ")
    assert_not result.success?
    assert_equal "Transaction hash is required.", result.error
  end

  test "withdrawal remains approved when transaction_hash is blank" do
    call_service(hash: "")
    assert @withdrawal.reload.approved?
  end

  test "does not enqueue a completion email when transaction_hash is blank" do
    assert_no_enqueued_emails do
      call_service(hash: "")
    end
  end

  test "returns failure for a duplicate transaction_hash" do
    existing = Withdrawal.create!(
      user:             @member,
      amount:           0.00500000,
      btc_address:      "bc1qduplicate",
      status:           :completed,
      requested_at:     Time.current,
      approved_at:      Time.current,
      completed_at:     Time.current,
      transaction_hash: "duplicate_hash_xyz",
      reviewed_by_id:   @admin.id
    )

    result = call_service(hash: "duplicate_hash_xyz")
    assert_not result.success?
    assert_match "already been used", result.error
  end

  # --- approved-only rule ---

  test "returns failure for a pending withdrawal" do
    @withdrawal.update!(status: :pending, approved_at: nil, reviewed_by_id: nil)
    result = call_service
    assert_not result.success?
    assert_equal "Withdrawal is not approved.", result.error
  end

  test "returns failure for a rejected withdrawal" do
    @withdrawal.update!(status: :rejected, rejected_at: Time.current)
    result = call_service
    assert_not result.success?
    assert_equal "Withdrawal is not approved.", result.error
  end

  test "returns failure for an already completed withdrawal" do
    @withdrawal.update!(
      status:           :completed,
      completed_at:     Time.current,
      transaction_hash: "existing_hash_abc"
    )
    result = call_service(hash: "new_hash_xyz")
    assert_not result.success?
    assert_equal "Withdrawal is not approved.", result.error
  end

  test "does not change status for an ineligible withdrawal" do
    @withdrawal.update!(status: :pending, approved_at: nil, reviewed_by_id: nil)
    call_service
    assert @withdrawal.reload.pending?
  end

  test "does not enqueue a completion email for an ineligible withdrawal" do
    @withdrawal.update!(status: :pending, approved_at: nil, reviewed_by_id: nil)
    assert_no_enqueued_emails do
      call_service
    end
  end

  # --- audit logging ---

  test "creates an audit log entry on completion" do
    assert_difference "AuditLog.count", 1 do
      call_service
    end

    log = AuditLog.last
    assert_equal "withdrawal.completed", log.action
    assert_equal @withdrawal, log.subject
  end

  test "records the given actor and ip_address on the audit log entry" do
    CompleteWithdrawalService.new(
      withdrawal:       @withdrawal,
      transaction_hash: "actorcheck#{SecureRandom.hex(8)}",
      actor:            @admin,
      ip_address:       "203.0.113.11"
    ).call

    log = AuditLog.last
    assert_equal @admin, log.actor
    assert_equal "203.0.113.11", log.ip_address
  end

  test "does not create an audit log entry for an ineligible withdrawal" do
    @withdrawal.update!(status: :pending, approved_at: nil, reviewed_by_id: nil)

    assert_no_difference "AuditLog.count" do
      call_service
    end
  end
end
