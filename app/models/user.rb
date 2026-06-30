class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable

  has_one  :wallet,   dependent: :destroy
  has_many :deposits, dependent: :destroy
  has_many :investments,    dependent: :restrict_with_exception
  has_many :profit_records, dependent: :restrict_with_exception
  has_many :withdrawals,    dependent: :restrict_with_exception
  has_many :reviewed_deposits,
           class_name:  "Deposit",
           foreign_key: :reviewed_by_id,
           dependent:   :nullify,
           inverse_of:  :reviewer

  has_many :reviewed_withdrawals,
           class_name:  "Withdrawal",
           foreign_key: :reviewed_by_id,
           dependent:   :nullify,
           inverse_of:  :reviewer

  enum :role, { member: 0, admin: 1 }, default: :member

  validates :full_name, presence: true, length: { maximum: 100 }
  validates :role,      presence: true

  after_commit :create_wallet!, on: :create

  def admin?
    role == "admin"
  end

  def member?
    role == "member"
  end

  def active_investments_count
    investments.active.count
  end

  def completed_investments_count
    investments.where(status: :completed).count
  end

  def total_invested_capital
    investments.sum(:principal_amount)
  end

  def total_profit_earned
    profit_records.sum(:amount)
  end

  private

  def create_wallet!
    Wallet.create!(user: self)
  end
end