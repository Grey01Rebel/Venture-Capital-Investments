# A read-only, non-persisted value object representing a single entry
# in a user's wallet activity feed. Built from existing ProfitRecord
# and Investment records — never persisted, never written to.
class WalletActivityEntry
  attr_reader :date, :activity_type, :investment, :amount

  PROFIT_CREDIT    = "Profit Credit"
  PRINCIPAL_RETURN = "Principal Return"

  def initialize(date:, activity_type:, investment:, amount:)
    @date          = date
    @activity_type = activity_type
    @investment    = investment
    @amount        = amount
  end

  def self.from_profit_record(profit_record)
    new(
      date:          profit_record.profit_date.to_time,
      activity_type: PROFIT_CREDIT,
      investment:    profit_record.investment,
      amount:        profit_record.amount
    )
  end

  def self.from_completed_investment(investment)
    new(
      date:          investment.completed_at,
      activity_type: PRINCIPAL_RETURN,
      investment:    investment,
      amount:        investment.principal_amount
    )
  end

  def profit_credit?
    activity_type == PROFIT_CREDIT
  end

  def principal_return?
    activity_type == PRINCIPAL_RETURN
  end
end