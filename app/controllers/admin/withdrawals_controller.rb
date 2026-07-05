class Admin::WithdrawalsController < Admin::BaseController
  before_action :set_withdrawal, only: [:show, :approve, :reject, :complete]

  def index
    @status_filter = params[:status].presence_in(%w[pending approved rejected completed]) || "pending"
    @search        = params[:search].to_s.strip
    @pagy, @withdrawals = pagy(
      Withdrawal.where(status: @status_filter)
                .search_by_term(@search)
                .includes(:user)
                .order(requested_at: :asc),
      items: 20
    )
  end

  def show
    authorize @withdrawal
  end

  def approve
    authorize @withdrawal
    result = WithdrawalReviewService.new(
      withdrawal:  @withdrawal,
      action:      :approve,
      reviewer:    current_user,
      admin_notes: params[:admin_notes].presence
    ).call

    if result.success?
      redirect_to admin_withdrawal_path(@withdrawal), notice: "Withdrawal approved."
    else
      redirect_to admin_withdrawal_path(@withdrawal), alert: result.error
    end
  end

  def reject
    authorize @withdrawal
    result = WithdrawalReviewService.new(
      withdrawal:  @withdrawal,
      action:      :reject,
      reviewer:    current_user,
      admin_notes: params[:admin_notes].presence
    ).call

    if result.success?
      redirect_to admin_withdrawal_path(@withdrawal), notice: "Withdrawal rejected and funds returned."
    else
      redirect_to admin_withdrawal_path(@withdrawal), alert: result.error
    end
  end

  def complete
    authorize @withdrawal
    result = CompleteWithdrawalService.new(
      withdrawal:       @withdrawal,
      transaction_hash: params[:transaction_hash]
    ).call

    if result.success?
      redirect_to admin_withdrawal_path(@withdrawal), notice: "Withdrawal marked as completed."
    else
      redirect_to admin_withdrawal_path(@withdrawal), alert: result.error
    end
  end

  private

  def set_withdrawal
    @withdrawal = Withdrawal.find(params[:id])
  end
end