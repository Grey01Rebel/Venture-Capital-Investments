# frozen_string_literal: true
require "test_helper"

class DepositMailerTest < ActionMailer::TestCase
  def setup
    @user  = create_confirmed_user(full_name: "Jane Investor")
    @admin = create_confirmed_user
    @admin.update!(role: :admin)
    @plan  = create_investment_plan(position: 1301)

    @deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "mail#{SecureRandom.hex(28)}",
      submitted_at:     Time.current
    )
  end

  # --- approved ---

  test "approved email is sent to the depositing user" do
    DepositReviewService.new(deposit: @deposit, action: :approve, reviewer: @admin).call
    mail = DepositMailer.approved(@deposit.reload)

    assert_equal [@user.email], mail.to
    assert_equal "Your deposit has been approved", mail.subject
  end

  test "approved email body includes the investment plan name" do
    DepositReviewService.new(deposit: @deposit, action: :approve, reviewer: @admin).call
    mail = DepositMailer.approved(@deposit.reload)

    assert_match @plan.name, mail.body.encoded
  end

  test "approved email body includes admin notes when present" do
    DepositReviewService.new(
      deposit: @deposit, action: :approve, reviewer: @admin, admin_notes: "Verified on chain."
    ).call
    mail = DepositMailer.approved(@deposit.reload)

    assert_match "Verified on chain.", mail.body.encoded
  end

  # --- rejected ---

  test "rejected email is sent to the depositing user" do
    DepositReviewService.new(deposit: @deposit, action: :reject, reviewer: @admin).call
    mail = DepositMailer.rejected(@deposit.reload)

    assert_equal [@user.email], mail.to
    assert_equal "Your deposit could not be approved", mail.subject
  end

  test "rejected email body includes admin notes when present" do
    DepositReviewService.new(
      deposit: @deposit, action: :reject, reviewer: @admin, admin_notes: "Hash not found."
    ).call
    mail = DepositMailer.rejected(@deposit.reload)

    assert_match "Hash not found.", mail.body.encoded
  end
end
