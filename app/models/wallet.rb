class Wallet < ApplicationRecord
  belongs_to :user

  validates :user, uniqueness: true
  validates :available_balance, :total_deposited, :total_withdrawn, :total_profit,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  MONETARY_FIELDS = %i[available_balance total_deposited total_withdrawn total_profit].freeze
end