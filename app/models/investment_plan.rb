# app/models/investment_plan.rb
class InvestmentPlan < ApplicationRecord
  validates :name,                 presence: true, uniqueness: true
  validates :investment_amount_usd, presence: true,
            numericality: { greater_than: 0 }
  validates :daily_return_rate,    presence: true,
            numericality: { greater_than: 0 }
  validates :duration_days,        presence: true,
            numericality: { greater_than: 0, only_integer: true }
  validates :position,             presence: true,
            numericality: { greater_than: 0, only_integer: true },
            uniqueness: true

  scope :active,   -> { where(active: true) }
  scope :ordered,  -> { order(:position) }
  scope :visible,  -> { active.ordered }
end