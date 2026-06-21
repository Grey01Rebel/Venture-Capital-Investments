# frozen_string_literal: true

class WalletActivitiesController < ApplicationController
  def index
    profit_entries = current_user.profit_records
                                 .includes(investment: :investment_plan)
                                 .map { |record| WalletActivityEntry.from_profit_record(record) }

    principal_return_entries = current_user.investments
                                           .completed
                                           .includes(:investment_plan)
                                           .map { |investment| WalletActivityEntry.from_completed_investment(investment) }

    @activity_entries = (profit_entries + principal_return_entries).sort_by(&:date).reverse
  end
end