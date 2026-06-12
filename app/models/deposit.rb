class Deposit < ApplicationRecord
  belongs_to :user
  belongs_to :investment_plan
  belongs_to :reviewer,
             class_name:  "User",
             foreign_key: :reviewed_by_id,
             optional:    true,
             inverse_of:  :reviewed_deposits

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :amount_usd,       presence: true,
            numericality: { greater_than: 0 }
  validates :btc_amount,       presence: true,
            numericality: { greater_than: 0 }
  validates :transaction_hash, presence: true,
            uniqueness: { case_insensitive: false }
  validates :submitted_at,     presence: true
  validates :status,           presence: true

  # Returns false if the deposit is not pending.
  # Sets status to approved, records approved_at, reviewer, and optional notes.
  def approve!(reviewer:, notes: nil)
    return false unless pending?

    update!(
      status:       :approved,
      approved_at:  Time.current,
      reviewer:     reviewer,
      admin_notes:  notes
    )
  end

  # Returns false if the deposit is not pending.
  # Sets status to rejected, records rejected_at, reviewer, and optional notes.
  def reject!(reviewer:, notes: nil)
    return false unless pending?

    update!(
      status:       :rejected,
      rejected_at:  Time.current,
      reviewer:     reviewer,
      admin_notes:  notes
    )
  end
end