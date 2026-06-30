class WithdrawalsController < ApplicationController
  def index
    @withdrawals = policy_scope(Withdrawal)
                     .order(requested_at: :desc)
                     .load
  end

  def show
    @withdrawal = Withdrawal.find(params[:id])
    authorize @withdrawal
  end

  def new
    @withdrawal = Withdrawal.new
    @wallet     = current_user.wallet
  end

  def create
    result = WithdrawalRequestService.new(
      user:        current_user,
      amount:      params[:withdrawal][:amount],
      btc_address: params[:withdrawal][:btc_address]
    ).call

    if result.success?
      redirect_to withdrawal_path(result.withdrawal), notice: "Withdrawal request submitted successfully."
    else
      @withdrawal = Withdrawal.new(
        amount:      params[:withdrawal][:amount],
        btc_address: params[:withdrawal][:btc_address]
      )
      @wallet = current_user.wallet
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end
end