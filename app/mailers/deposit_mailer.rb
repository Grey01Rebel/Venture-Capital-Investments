# frozen_string_literal: true
class DepositMailer < ApplicationMailer
  # Sent when a member's deposit has been approved and its investment created.
  def approved(deposit)
    @deposit = deposit
    @user    = deposit.user
    @plan    = deposit.investment_plan
    @investment = deposit.investment

    mail(
      to:      @user.email,
      subject: "Your deposit has been approved"
    )
  end

  # Sent when a member's deposit has been rejected.
  def rejected(deposit)
    @deposit = deposit
    @user    = deposit.user
    @plan    = deposit.investment_plan

    mail(
      to:      @user.email,
      subject: "Your deposit could not be approved"
    )
  end
end
