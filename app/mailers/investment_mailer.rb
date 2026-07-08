# frozen_string_literal: true
class InvestmentMailer < ApplicationMailer
  # Sent when an investment matures and its principal is returned to the
  # member's wallet. Per ADR-017, this is the only investment lifecycle
  # event that generates a transactional email in this milestone — daily
  # profit credits are deliberately not emailed individually.
  def completed(investment)
    @investment = investment
    @user       = investment.user
    @plan       = investment.investment_plan

    mail(
      to:      @user.email,
      subject: "Your investment has completed"
    )
  end
end
