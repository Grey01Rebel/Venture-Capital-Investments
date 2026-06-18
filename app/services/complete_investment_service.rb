class CompleteInvestmentService
  Result = Struct.new(:success?, :investment, :error, keyword_init: true)

  def initialize(investment)
    @investment = investment
  end

  def call
    return failure("Investment is already completed.") if @investment.completed?
    return failure("Investment is not active.") unless @investment.active?
    return failure("Investment has not yet reached its end date.") unless end_date_reached?

    wallet = @investment.user.wallet
    return failure("User wallet not found.") if wallet.nil?

    ActiveRecord::Base.transaction do
      @investment.update!(
        status:       :completed,
        completed_at: Time.current
      )

      wallet.update!(
        available_balance: wallet.available_balance + @investment.principal_amount
      )
    end

    Result.new(success?: true, investment: @investment, error: nil)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence)
  rescue StandardError => e
    failure("Investment completion failed: #{e.message}")
  end

  private

  def end_date_reached?
    @investment.ends_at <= Time.current
  end

  def failure(message)
    Result.new(success?: false, investment: nil, error: message)
  end
end