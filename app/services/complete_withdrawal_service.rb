# frozen_string_literal: true
class CompleteWithdrawalService
  Result = Struct.new(:success?, :withdrawal, :error, keyword_init: true)

  def initialize(withdrawal:, transaction_hash:, actor: nil, ip_address: nil)
    @withdrawal       = withdrawal
    @transaction_hash = transaction_hash.to_s.strip
    @actor            = actor
    @ip_address       = ip_address
  end

  def call
    return failure("Withdrawal is not approved.")      unless @withdrawal.approved?
    return failure("Transaction hash is required.")    if @transaction_hash.blank?

    @withdrawal.update!(
      status:           :completed,
      completed_at:     Time.current,
      transaction_hash: @transaction_hash
    )

    WithdrawalMailer.completed(@withdrawal).deliver_later

    AuditLog.record!(
      action:     "withdrawal.completed",
      actor:      @actor,
      subject:    @withdrawal,
      ip_address: @ip_address
    )

    Result.new(success?: true, withdrawal: @withdrawal, error: nil)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence)
  rescue ActiveRecord::RecordNotUnique
    failure("This transaction hash has already been used.")
  end

  private

  def failure(message)
    Result.new(success?: false, withdrawal: nil, error: message)
  end
end
