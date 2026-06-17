class Investment < ApplicationRecord
  belongs_to :user
  belongs_to :deposit
  belongs_to :investment_plan

  has_many :profit_records, dependent: :restrict_with_exception

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
end