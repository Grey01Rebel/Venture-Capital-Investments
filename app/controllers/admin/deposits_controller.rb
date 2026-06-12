module Admin
  class DepositsController < Admin::BaseController
    before_action :set_deposit, only: [:show, :approve, :reject]

    def index
      @status_filter = params[:status].presence_in(%w[pending approved rejected]) || "pending"
      @deposits = policy_scope(Deposit)
                    .where(status: @status_filter)
                    .includes(:user, :investment_plan)
                    .order(submitted_at: :asc)
                    .load
    end

    def show
      authorize @deposit
    end

    def approve
      authorize @deposit, :approve?

      if @deposit.approve!(reviewer: current_user, notes: params[:admin_notes].presence)
        redirect_to admin_deposit_path(@deposit),
                    notice: "Deposit approved successfully."
      else
        redirect_to admin_deposit_path(@deposit),
                    alert: "This deposit has already been reviewed and cannot be approved."
      end
    end

    def reject
      authorize @deposit, :reject?

      if @deposit.reject!(reviewer: current_user, notes: params[:admin_notes].presence)
        redirect_to admin_deposit_path(@deposit),
                    notice: "Deposit rejected successfully."
      else
        redirect_to admin_deposit_path(@deposit),
                    alert: "This deposit has already been reviewed and cannot be rejected."
      end
    end

    private

    def set_deposit
      @deposit = Deposit.find(params[:id])
    end
  end
end