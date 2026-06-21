class Investment < ApplicationRecord
  belongs_to :user
  belongs_to :deposit
  belongs_to :investment_plan

  has_many :profit_records, dependent: :restrict_with_exception

  enum :status, { active: 0, completed: 1 }, default: :active

  scope :active, -> { where(status: :active) }

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

  def active?
    status == "active"
  end

  def completed?
    status == "completed"
  end

  def complete!
    return false if completed?

    update!(status: :completed)
  end

  # --- Performance metrics, derived from associated profit_records ---

  # Sum of all profit recorded against this investment.
  def total_profit_earned
    profit_records.sum(:amount)
  end

  # Number of distinct days profit has been recorded for this investment.
  def days_paid
    profit_records.count
  end

  # Days remaining in the investment term. Never negative.
  def remaining_days
    [duration_days - days_paid, 0].max
  end
end