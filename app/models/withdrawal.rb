# frozen_string_literal: true
class Withdrawal < ApplicationRecord
  belongs_to :user
  belongs_to :reviewer, class_name: "User", optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2, completed: 3 }, default: :pending

  validates :amount,      presence: true,
            numericality: { greater_than: 0 }
  validates :btc_address, presence: true
  validates :status,      presence: true

  # Wallet balance validation is intentionally deferred to a future
  # submission service. This model only enforces structural validity.
end
