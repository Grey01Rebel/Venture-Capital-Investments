require "application_system_test_case"

class WalletActivityTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      full_name:             "Wallet Admin",
      email:                 "wallet_admin@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @admin.confirm
    @admin.update!(role: :admin)

    @member = User.create!(
      full_name:             "Wallet Investor",
      email:                 "wallet_investor@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @member.confirm

    create_all_six_plans
    @plan = InvestmentPlan.find_by(name: "Starter")
  end

  def build_investment(hash_prefix)
    deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "#{hash_prefix}#{SecureRandom.hex(24)}",
      submitted_at:     Time.current
    )
    DepositReviewService.new(deposit: deposit, action: :approve, reviewer: @admin).call
    deposit.reload
    deposit.investment
  end

  test "profit credits are displayed in wallet activity" do
    investment = build_investment("sysact1")
    ProfitRecord.create!(
      user:        @member,
      investment:  investment,
      amount:      4.00,
      profit_date: Date.current
    )

    login_as @member
    visit wallet_activity_path

    assert_text "Wallet Activity"
    assert_text "Profit Credit"
    assert_text "$4.00"
    assert_text "Starter"
  end

  test "principal returns are displayed in wallet activity" do
    investment = build_investment("sysact2")
    investment.update!(status: :completed, completed_at: Time.current)

    login_as @member
    visit wallet_activity_path

    assert_text "Principal Return"
    assert_text "$500.00"
    assert_text "Starter"
  end

  test "activity feed displays in reverse chronological order" do
    investment = build_investment("sysact3")

    ProfitRecord.create!(
      user:        @member,
      investment:  investment,
      amount:      4.00,
      profit_date: Date.current - 5
    )
    ProfitRecord.create!(
      user:        @member,
      investment:  investment,
      amount:      4.00,
      profit_date: Date.current
    )

    login_as @member
    visit wallet_activity_path

    rows = all("table tbody tr")
    first_row_date  = rows[0].text
    second_row_date = rows[1].text

    assert first_row_date.include?(Date.current.strftime("%b %d"))
    assert second_row_date.include?((Date.current - 5).strftime("%b %d"))
  end

  test "empty state displayed when user has no wallet activity" do
    login_as @member
    visit wallet_activity_path

    assert_text "No wallet activity yet."
    assert_text "Browse Investment Plans"
  end

  test "Wallet Activity navigation link works" do
    login_as @member
    visit authenticated_root_path
    assert_selector "a[href='#{wallet_activity_path}']"
    click_link "Wallet Activity"
    assert_current_path wallet_activity_path
    assert_text "Wallet Activity"
  end

  test "unauthenticated user is redirected from wallet activity page" do
    visit wallet_activity_path
    assert_current_path new_user_session_path
  end
end