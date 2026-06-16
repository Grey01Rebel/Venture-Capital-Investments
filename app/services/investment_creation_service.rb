# frozen_string_literal: true
class InvestmentCreationService
  Result = Struct.new(:success?, :investment, :error, keyword_init: true)

  def initialize(deposit)
    @deposit = deposit
  end

  def call
    return failure("Deposit is not approved.") unless @deposit.approved?
    return failure("An investment already exists for this deposit.") if @deposit.investment.present?

    plan       = @deposit.investment_plan
    started_at = @deposit.approved_at
    ends_at    = started_at + plan.duration_days.days

    investment = Investment.new(
      user:              @deposit.user,
      deposit:           @deposit,
      investment_plan:   plan,
      principal_amount:  @deposit.amount_usd,
      daily_return_rate: plan.daily_return_rate,
      duration_days:     plan.duration_days,
      started_at:        started_at,
      ends_at:           ends_at,
      status:            :active
    )

    if investment.save
      Result.new(success?: true, investment: investment, error: nil)
    else
      Result.new(success?: false, investment: nil, error: investment.errors.full_messages.to_sentence)
    end
  end

  private

  def failure(message)
    Result.new(success?: false, investment: nil, error: message)
  end
end
