class WithdrawalRequestService
  Result = Struct.new(:success?, :withdrawal, :error, keyword_init: true)

  def initialize(user:, amount:, btc_address:)
    @user        = user
    @amount      = amount.to_d rescue BigDecimal("0")
    @btc_address = btc_address
  end

  def call
    return failure("Amount must be greater than zero.") unless positive_amount?

    wallet = @user.wallet
    return failure("Wallet not found.") if wallet.nil? || wallet.destroyed?
    return failure("Insufficient balance.") if @amount > wallet.available_balance

    withdrawal = nil

    ActiveRecord::Base.transaction do
      withdrawal = Withdrawal.create!(
        user:         @user,
        amount:       @amount,
        btc_address:  @btc_address,
        status:       :pending,
        requested_at: Time.current
      )

      wallet.update!(
        available_balance: wallet.available_balance - @amount
      )
    end

    Result.new(success?: true, withdrawal: withdrawal, error: nil)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence)
  end

  private

  def positive_amount?
    @amount > 0
  end

  def failure(message)
    Result.new(success?: false, withdrawal: nil, error: message)
  end
end