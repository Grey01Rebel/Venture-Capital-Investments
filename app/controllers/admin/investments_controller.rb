# frozen_string_literal: true
class Admin::InvestmentsController < Admin::BaseController
  def index
    @status_filter = params[:status].presence_in(%w[active completed]) || ""
    @search        = params[:search].to_s.strip
    @pagy, @investments = pagy(
      Investment.by_status(@status_filter)
                .search_by_term(@search)
                .includes(:user, :investment_plan)
                .order(started_at: :desc),
      items: 20
    )
  end
end
