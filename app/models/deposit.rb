class Deposit < ApplicationRecord
  belongs_to :user
  belongs_to :investment_plan

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :amount_usd,       presence: true,
            numericality: { greater_than: 0 }
  validates :btc_amount,       presence: true,
            numericality: { greater_than: 0 }
  validates :transaction_hash, presence: true,
            uniqueness: { case_insensitive: false }
  validates :submitted_at,     presence: true
  validates :status,           presence: true
end