class PlansController < ApplicationController
  def index
    @plans = policy_scope(InvestmentPlan).load
  end
end