class ProfitsController < ApplicationController
  def index
    @profit_records = policy_scope(ProfitRecord)
                        .includes(investment: :investment_plan)
                        .order(profit_date: :desc)
                        .load
  end
end