# frozen_string_literal: true
class InvestmentsController < ApplicationController
  def index
    @investments = policy_scope(Investment)
                     .includes(:investment_plan, :deposit)
                     .order(started_at: :desc)
                     .load
  end

  def show
    @investment = Investment.find(params[:id])
    authorize @investment
  end
end
