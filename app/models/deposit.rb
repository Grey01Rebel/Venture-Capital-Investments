class Deposit < ApplicationRecord
  belongs_to :user
  belongs_to :investment_plan
  belongs_to :reviewer,
             class_name:  "User",
             foreign_key: :reviewed_by_id,
             optional:    true,
             inverse_of:  :reviewed_deposits

  has_one :investment, dependent: :restrict_with_exception

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :amount_usd,       presence: true,
            numericality: { greater_than: 0 }
  validates :btc_amount,       presence: true,
            numericality: { greater_than: 0 }
  validates :transaction_hash, presence: true,
            uniqueness: { case_insensitive: false }
  validates :submitted_at,     presence: true
  validates :status,           presence: true

  def approve!(reviewer:, notes: nil)
    return false unless pending?

    investment_succeeded = false

    transaction do
      update!(
        status:       :approved,
        approved_at:  Time.current,
        reviewer:     reviewer,
        admin_notes:  notes
      )

      result = InvestmentCreationService.new(self).call

      if result.success?
        investment_succeeded = true
      else
        raise ActiveRecord::Rollback, result.error
      end
    end

    investment_succeeded
  end

  def reject!(reviewer:, notes: nil)
    return false unless pending?

    update!(
      status:       :rejected,
      rejected_at:  Time.current,
      reviewer:     reviewer,
      admin_notes:  notes
    )
  end
end