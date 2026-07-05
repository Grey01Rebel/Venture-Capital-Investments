class GenerateDailyProfitService
  Result = Struct.new(:success?, :profit_record, :error, keyword_init: true)

  def initialize(investment, profit_date)
    @investment  = investment
    @profit_date = profit_date
  end

  def call
    return failure("Investment is not active.") unless @investment.active?
    return failure("Profit has already been generated for this date.") if profit_already_exists?

    wallet = @investment.user.wallet
    return failure("User wallet not found.") if wallet.nil?

    profit_amount = calculate_daily_profit
    profit_record = nil

    # Acquire a row-level lock on the wallet before crediting profit.
    # GenerateDailyProfitsJob processes investments sequentially but may run
    # concurrently with other jobs or admin actions. The lock ensures that
    # available_balance and total_profit are always read and written atomically.
    wallet.with_lock do
      profit_record = ProfitRecord.create!(
        user:        @investment.user,
        investment:  @investment,
        amount:      profit_amount,
        profit_date: @profit_date
      )

      wallet.update!(
        available_balance: wallet.available_balance + profit_amount,
        total_profit:       wallet.total_profit + profit_amount
      )
    end

    Result.new(success?: true, profit_record: profit_record, error: nil)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence)
  rescue ActiveRecord::RecordNotUnique
    failure("Profit has already been generated for this date.")
  end

  private

  def profit_already_exists?
    ProfitRecord.exists?(investment: @investment, profit_date: @profit_date)
  end

  def calculate_daily_profit
    @investment.principal_amount * (@investment.daily_return_rate / 100)
  end

  def failure(message)
    Result.new(success?: false, profit_record: nil, error: message)
  end
end