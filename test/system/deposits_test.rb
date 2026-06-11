require "application_system_test_case"

class DepositsTest < ApplicationSystemTestCase
  def setup
    @user = User.create!(
      full_name: "Deposit Tester",
      email:     "deposittester@example.com",
      password:  "password123",
      password_confirmation: "password123"
    )
    @user.confirm
    create_all_six_plans
    @plan = InvestmentPlan.find_by(name: "Starter")
  end

  # User selects a plan and reaches deposit form
  test "user selects a plan and sees deposit form" do
    login_as @user
    visit plans_path
    assert_selector "a", text: "Start Investment"
    first("a", text: "Start Investment").click
    assert_text "Submit Deposit"
    assert_text "Starter"
    assert_text "$500.00"
  end

  # User creates a deposit
  test "user fills in deposit form and submits successfully" do
    login_as @user
    visit new_deposit_path(investment_plan_id: @plan.id)
    fill_in "BTC Amount Sent",        with: "0.00812345"
    fill_in "Transaction Hash (TXID)", with: "sys#{SecureRandom.hex(30)}"
    click_button "Submit Deposit"
    assert_text "Deposit submitted successfully"
    assert_text "Pending"
    assert_text "Starter"
    assert_text "$500.00"
  end

  # Deposit appears on index page
  test "submitted deposit appears on deposits index" do
    deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "idx#{SecureRandom.hex(30)}",
      submitted_at:     Time.current
    )
    login_as @user
    visit deposits_path
    assert_text "Starter"
    assert_text "$500.00"
    assert_text "Pending"
  end

  # Deposit show page loads
  test "deposit show page displays all details" do
    deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "show#{SecureRandom.hex(30)}",
      submitted_at:     Time.current
    )
    login_as @user
    visit deposit_path(deposit)
    assert_text "Starter"
    assert_text "$500.00"
    assert_text "0.00812345"
    assert_text deposit.transaction_hash
    assert_text "Pending"
  end

  # Status displays correctly
  test "pending status displays with correct label" do
    deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "stat#{SecureRandom.hex(30)}",
      submitted_at:     Time.current,
      status:           :pending
    )
    login_as @user
    visit deposit_path(deposit)
    assert_text "Pending"
  end

  # Unauthenticated user redirected
  test "unauthenticated user cannot access deposits" do
    visit deposits_path
    assert_current_path new_user_session_path
  end

  # My Deposits nav link present
  test "authenticated user sees My Deposits link in navbar" do
    login_as @user
    visit authenticated_root_path
    assert_selector "a[href='#{deposits_path}']"
  end
end