# frozen_string_literal: true
class DepositReviewService
  Result = Struct.new(:success?, :deposit, :error, keyword_init: true)

  def initialize(deposit:, action:, reviewer:, admin_notes: nil, ip_address: nil)
    @deposit     = deposit
    @action      = action
    @reviewer    = reviewer
    @admin_notes = admin_notes
    @ip_address  = ip_address
  end

  def call
    return failure("Deposit is not pending.") unless @deposit.pending?

    case @action
    when :approve then perform_approval
    when :reject   then perform_rejection
    else failure("Unknown action: #{@action}.")
    end
  end

  private

  def perform_approval
    error_message = nil

    # The deposit's status transition and the resulting investment creation
    # must succeed or fail together. If investment creation fails, the
    # deposit approval is rolled back so it remains pending and reviewable.
    ActiveRecord::Base.transaction do
      unless @deposit.approve!(reviewer: @reviewer, notes: @admin_notes)
        error_message = "Deposit could not be approved."
        raise ActiveRecord::Rollback
      end

      result = InvestmentCreationService.new(@deposit).call

      unless result.success?
        error_message = result.error
        raise ActiveRecord::Rollback
      end
    end

    if error_message
      failure(error_message)
    else
      @deposit.reload
      DepositMailer.approved(@deposit).deliver_later
      AuditLog.record!(
        action:     "deposit.approved",
        actor:      @reviewer,
        subject:    @deposit,
        ip_address: @ip_address
      )
      Result.new(success?: true, deposit: @deposit, error: nil)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence)
  end

  def perform_rejection
    if @deposit.reject!(reviewer: @reviewer, notes: @admin_notes)
      DepositMailer.rejected(@deposit).deliver_later
      AuditLog.record!(
        action:     "deposit.rejected",
        actor:      @reviewer,
        subject:    @deposit,
        ip_address: @ip_address
      )
      Result.new(success?: true, deposit: @deposit, error: nil)
    else
      failure("Deposit could not be rejected.")
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence)
  end

  def failure(message)
    Result.new(success?: false, deposit: nil, error: message)
  end
end
