# frozen_string_literal: true
require "test_helper"

class InvestmentMailerTest < ActionMailer::TestCase
  def setup
    @user  = create_confirmed_user(full_name: "Jane Investor")
    @admin = create_confirmed_user
    @admin.update!(role: :admin)
    @plan  = create_investment_plan(position: 1801, investment_amount_usd: 500.00)

    deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "invmail#{SecureRandom.hex(26)}",
      submitted_at:     Time.current
    )
    DepositReviewService.new(deposit: deposit, action: :approve, reviewer: @admin).call
    @investment = deposit.reload.investment
    @investment.update!(ends_at: 1.day.ago)
  end

  test "completed email is sent to the investing user" do
    CompleteInvestmentService.new(@investment).call
    mail = InvestmentMailer.completed(@investment.reload)

    assert_equal [@user.email], mail.to
    assert_equal "Your investment has completed", mail.subject
  end

  test "completed email body includes the investment plan name" do
    CompleteInvestmentService.new(@investment).call
    mail = InvestmentMailer.completed(@investment.reload)

    assert_match @plan.name, mail.body.encoded
  end

  test "completed email body includes total profit earned" do
    CompleteInvestmentService.new(@investment).call
    mail = InvestmentMailer.completed(@investment.reload)

    assert_match "Total profit earned", mail.body.encoded
  end
end
