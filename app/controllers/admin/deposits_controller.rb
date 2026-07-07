class Admin::DepositsController < Admin::BaseController
  before_action :set_deposit, only: [:show, :approve, :reject]

  def index
    @status_filter = params[:status].presence_in(%w[pending approved rejected]) || "pending"
    @search        = params[:search].to_s.strip
    @pagy, @deposits = pagy(
      Deposit.where(status: @status_filter)
             .search_by_term(@search)
             .includes(:user, :investment_plan)
             .order(submitted_at: :asc),
      items: 20
    )
  end

  def show
    authorize @deposit
  end

  def approve
    authorize @deposit
    result = DepositReviewService.new(
      deposit:     @deposit,
      action:      :approve,
      reviewer:    current_user,
      admin_notes: params[:admin_notes].presence
    ).call

    if result.success?
      redirect_to admin_deposit_path(@deposit), notice: "Deposit approved successfully."
    else
      redirect_to admin_deposit_path(@deposit), alert: "This deposit has already been reviewed and cannot be approved."
    end
  end

  def reject
    authorize @deposit
    result = DepositReviewService.new(
      deposit:     @deposit,
      action:      :reject,
      reviewer:    current_user,
      admin_notes: params[:admin_notes].presence
    ).call

    if result.success?
      redirect_to admin_deposit_path(@deposit), notice: "Deposit rejected successfully."
    else
      redirect_to admin_deposit_path(@deposit), alert: "This deposit has already been reviewed and cannot be rejected."
    end
  end

  private

  def set_deposit
    @deposit = Deposit.find(params[:id])
  end
end