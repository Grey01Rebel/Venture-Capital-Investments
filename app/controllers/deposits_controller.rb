class DepositsController < ApplicationController
  before_action :set_plan, only: [:new, :create]

  def index
    @deposits = policy_scope(Deposit).includes(:investment_plan)
                                     .order(submitted_at: :desc)
                                     .load
  end

  def show
    @deposit = Deposit.find(params[:id])
    authorize @deposit
  end

  def new
    @deposit    = Deposit.new(investment_plan: @plan)
    @btc_address = ENV.fetch("COMPANY_BTC_ADDRESS", nil)
    authorize @deposit
  end

  def create
    @deposit = current_user.deposits.build(deposit_params)
    @deposit.investment_plan = @plan
    @deposit.amount_usd      = @plan.investment_amount_usd
    @deposit.submitted_at    = Time.current
    authorize @deposit

    if @deposit.save
      redirect_to deposit_path(@deposit),
                  notice: "Deposit submitted successfully. Your deposit is pending review."
    else
      @btc_address = ENV.fetch("COMPANY_BTC_ADDRESS", nil)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_plan
    @plan = InvestmentPlan.active.find_by(id: params[:investment_plan_id])

    unless @plan
      redirect_to plans_path, alert: "Invalid or inactive investment plan selected."
    end
  end

  def deposit_params
    params.require(:deposit).permit(:btc_amount, :transaction_hash)
  end
end