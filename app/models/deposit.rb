class Deposit < ApplicationRecord
  belongs_to :user
  belongs_to :investment_plan
  belongs_to :reviewer, class_name: "User", foreign_key: :reviewed_by_id, optional: true
  has_one :investment, dependent: :restrict_with_exception

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :amount_usd,        presence: true, numericality: { greater_than: 0 }
  validates :btc_amount,        presence: true, numericality: { greater_than: 0 }
  validates :transaction_hash,  presence: true, uniqueness: true
  validates :submitted_at,      presence: true
  validates :status,            presence: true

  scope :search_by_term, ->(term) {
    return all if term.blank?
    sanitized = "%#{sanitize_sql_like(term.strip)}%"
    joins(:user)
      .where(
        "users.full_name ILIKE :term OR users.email ILIKE :term OR deposits.transaction_hash ILIKE :term",
        term: sanitized
      )
  }

  # Pure state transition — approving a deposit does not, by itself, create
  # an investment. Orchestrating that workflow is the responsibility of
  # DepositReviewService.
  def approve!(reviewer:, notes: nil)
    return false unless pending?

    update!(
      status:       :approved,
      approved_at:  Time.current,
      reviewer:     reviewer,
      admin_notes:  notes
    )
  end

  # Pure state transition — see approve! above.
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