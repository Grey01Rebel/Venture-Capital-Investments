class Investment < ApplicationRecord
  belongs_to :user
  belongs_to :deposit
  belongs_to :investment_plan

  has_many :profit_records, dependent: :restrict_with_exception

  enum :status, { active: 0, completed: 1 }, default: :active

  scope :active,        -> { where(status: :active) }
  scope :by_status,     ->(status) { status.present? ? where(status: status) : all }
  scope :search_by_term, ->(term) {
    return all if term.blank?
    sanitized = "%#{sanitize_sql_like(term.strip)}%"
    joins(:user, :investment_plan)
      .where(
        "users.full_name ILIKE :term OR users.email ILIKE :term OR investment_plans.name ILIKE :term",
        term: sanitized
      )
  }

  validates :principal_amount,  presence: true, numericality: { greater_than: 0 }
  validates :daily_return_rate, presence: true, numericality: { greater_than: 0 }
  validates :duration_days,     presence: true, numericality: { greater_than: 0, only_integer: true }
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

  def total_profit_earned
    profit_records.sum(:amount)
  end

  def days_paid
    profit_records.count
  end

  def remaining_days
    [duration_days - days_paid, 0].max
  end
end