class ProfitRecord < ApplicationRecord
  belongs_to :user
  belongs_to :investment

  validates :amount,        presence: true,
            numericality: { greater_than: 0 }
  validates :profit_date,   presence: true
  validates :investment_id, presence: true,
            uniqueness: { scope: :profit_date }
  validates :user_id,       presence: true

  # ProfitRecord is a historical, immutable ledger entry.
  # It intentionally contains no calculation logic, no wallet updates,
  # and no methods that generate or mutate profit values.
  # Profit amounts are computed elsewhere and passed in at creation time.
end