class Withdrawal < ApplicationRecord
  belongs_to :user
  belongs_to :reviewer, class_name: "User", foreign_key: :reviewed_by_id, optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2, completed: 3 }, default: :pending

  validates :amount,           presence: true,
            numericality: { greater_than: 0 }
  validates :btc_address,      presence: true
  validates :status,           presence: true
  validates :transaction_hash, presence: true, if: :completed?

  # Wallet balance validation is intentionally deferred to WithdrawalRequestService.
  # transaction_hash is only required when status is completed.
end