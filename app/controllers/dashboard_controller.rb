class DashboardController < ApplicationController
  def index
    @wallet = current_user.wallet
    authorize @wallet, :show?
  end
end
