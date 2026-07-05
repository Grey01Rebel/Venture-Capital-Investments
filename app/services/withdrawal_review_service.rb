class WithdrawalReviewService
  Result = Struct.new(:success?, :withdrawal, :error, keyword_init: true)

  def initialize(withdrawal:, action:, reviewer:, admin_notes: nil)
    @withdrawal  = withdrawal
    @action      = action
    @reviewer    = reviewer
    @admin_notes = admin_notes
  end

  def call
    return failure("Withdrawal is not pending.") unless @withdrawal.pending?

    case @action
    when :approve then perform_approval
    when :reject  then perform_rejection
    else failure("Unknown action: #{@action}.")
    end
  end

  private

  def perform_approval
    # Approval does not mutate the wallet — funds were reserved at submission.
    # No locking required here.
    @withdrawal.update!(
      status:       :approved,
      approved_at:  Time.current,
      reviewer:     @reviewer,
      admin_notes:  @admin_notes
    )

    Result.new(success?: true, withdrawal: @withdrawal, error: nil)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence)
  end

  def perform_rejection
    wallet = @withdrawal.user.wallet
    return failure("User wallet not found.") if wallet.nil? || wallet.destroyed?

    # Acquire a row-level lock on the wallet before crediting the reserved funds
    # back. This prevents a concurrent rejection of a different withdrawal for
    # the same user from reading a stale balance and producing an incorrect total.
    wallet.with_lock do
      @withdrawal.update!(
        status:       :rejected,
        rejected_at:  Time.current,
        reviewer:     @reviewer,
        admin_notes:  @admin_notes
      )

      wallet.update!(
        available_balance: wallet.available_balance + @withdrawal.amount
      )
    end

    Result.new(success?: true, withdrawal: @withdrawal, error: nil)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence)
  end

  def failure(message)
    Result.new(success?: false, withdrawal: nil, error: message)
  end
end