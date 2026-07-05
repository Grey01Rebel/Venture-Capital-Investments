# frozen_string_literal: true
class Admin::DashboardController < Admin::BaseController
  def index
    # Platform overview
    @total_users   = User.count
    @total_members = User.where(role: :member).count
    @total_admins  = User.where(role: :admin).count

    # Deposits
    @pending_deposits  = Deposit.where(status: :pending).count
    @approved_deposits = Deposit.where(status: :approved).count
    @rejected_deposits = Deposit.where(status: :rejected).count

    # Withdrawals
    @pending_withdrawals   = Withdrawal.where(status: :pending).count
    @approved_withdrawals  = Withdrawal.where(status: :approved).count
    @completed_withdrawals = Withdrawal.where(status: :completed).count
    @rejected_withdrawals  = Withdrawal.where(status: :rejected).count

    # Investments
    @active_investments    = Investment.where(status: :active).count
    @completed_investments = Investment.where(status: :completed).count

    # Financial overview
    @total_btc_available    = Wallet.sum(:available_balance)
    @total_invested_capital = Investment.sum(:principal_amount)
    @total_profit_paid      = ProfitRecord.sum(:amount)
    @total_principal_returned = Investment.where(status: :completed).sum(:principal_amount)

    # Recent activity — bounded at 10 rows per source, 40 total
    recent_deposits     = Deposit.includes(:user, :investment_plan)
                                 .order(created_at: :desc).limit(10)
    recent_withdrawals  = Withdrawal.includes(:user)
                                    .order(created_at: :desc).limit(10)
    recent_investments  = Investment.includes(:user, :investment_plan)
                                    .order(created_at: :desc).limit(10)
    recent_completions  = Withdrawal.where(status: :completed)
                                    .includes(:user)
                                    .order(completed_at: :desc).limit(10)

    @recent_activity = build_activity_feed(
      recent_deposits, recent_withdrawals, recent_investments, recent_completions
    )
  end

  private

  def build_activity_feed(*collections)
    collections.flatten.map do |record|
      case record
      when Deposit
        { type: "Deposit", label: record.investment_plan.name,
          user: record.user.full_name, amount: record.amount_usd,
          unit: "USD", status: record.status,
          occurred_at: record.created_at }
      when Withdrawal
        label = record.completed? ? "Withdrawal Completed" : "Withdrawal Requested"
        { type: label, label: nil,
          user: record.user.full_name, amount: record.amount,
          unit: "BTC", status: record.status,
          occurred_at: record.completed_at || record.created_at }
      when Investment
        { type: "Investment Created", label: record.investment_plan.name,
          user: record.user.full_name, amount: record.principal_amount,
          unit: "USD", status: record.status,
          occurred_at: record.created_at }
      end
    end.sort_by { |e| e[:occurred_at] }.reverse.first(10)
  end
end
