class InvestmentsController < ApplicationController
  def index
    @investments = policy_scope(Investment)
                     .includes(:investment_plan, :deposit)
                     .order(started_at: :desc)
                     .load
  end

  def show
    @investment = Investment.includes(:profit_records).find(params[:id])
    authorize @investment
  end
end