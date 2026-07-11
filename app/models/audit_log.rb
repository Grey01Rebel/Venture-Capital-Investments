class AuditLog < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true, optional: true

  # The full event taxonomy for this application. New events are added
  # here — and only here — as each is actually wired up; do not add an
  # event before the code path that triggers it exists.
  #
  # `action` is deliberately a validated string, not a Rails `enum`.
  # `enum` models mutable state a record transitions through (see
  # Deposit#status, Withdrawal#status); `action` is a write-once
  # classification chosen at creation and never revisited. See
  # docs/Decisions.md, ADR-020.
  ACTIONS = %w[
    deposit.approved
    deposit.rejected
    withdrawal.approved
    withdrawal.rejected
    withdrawal.completed
    investment.completed
    authorization.denied
    user.signed_in
    user.sign_in_failed
    user.signed_out
    user.password_reset_requested
    user.password_reset_completed
  ].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }

  before_update  { raise ActiveRecord::ReadOnlyRecord, "AuditLog records are immutable" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "AuditLog records cannot be deleted" }

  # The single sanctioned way to create an audit log entry. Every call
  # site — services, controllers, the Warden failure hook — goes through
  # this method rather than AuditLog.create!/.new directly, so there is
  # one logging API regardless of where an event originates.
  def self.record!(action:, actor: nil, subject: nil, ip_address: nil, metadata: {})
    create!(
      action:     action,
      actor:      actor,
      subject:    subject,
      ip_address: ip_address,
      metadata:   metadata
    )
  end
end
