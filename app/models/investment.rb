# frozen_string_literal: true
class Investment < ApplicationRecord
  belongs_to :user
  belongs_to :deposit
  belongs_to :investment_plan

  enum :status, { active: 0, completed: 1 }, default: :active

  validates :principal_amount,  presence: true,
            numericality: { greater_than: 0 }
  validates :daily_return_rate, presence: true,
            numericality: { greater_than: 0 }
  validates :duration_days,     presence: true,
            numericality: { greater_than: 0, only_integer: true }
  validates :started_at,        presence: true
  validates :ends_at,           presence: true
  validates :status,            presence: true
  validates :deposit_id,        uniqueness: true

  # Returns true if the investment is active.
  def active?
    status == "active"
  end

  # Returns true if the investment is completed.
  def completed?
    status == "completed"
  end

  # Marks the investment as completed.
  # Safe to call repeatedly — returns false without side effects if already completed.
  def complete!
    return false if completed?

    update!(status: :completed)
  end
end
