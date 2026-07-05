class Withdrawal < ApplicationRecord
  belongs_to :user
  belongs_to :reviewer, class_name: "User", foreign_key: :reviewed_by_id, optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2, completed: 3 }, default: :pending

  validates :amount,           presence: true, numericality: { greater_than: 0 }
  validates :btc_address,      presence: true
  validates :status,           presence: true
  validates :transaction_hash, presence: true, if: :completed?

  scope :search_by_term, ->(term) {
    return all if term.blank?
    sanitized = "%#{sanitize_sql_like(term.strip)}%"
    joins(:user)
      .where(
        "users.full_name ILIKE :term OR users.email ILIKE :term OR withdrawals.transaction_hash ILIKE :term OR withdrawals.btc_address ILIKE :term",
        term: sanitized
      )
  }
end