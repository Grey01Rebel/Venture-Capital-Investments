# frozen_string_literal: true
require "application_system_test_case"

class InvestmentsTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      full_name:             "Admin User",
      email:                 "inv_admin@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @admin.confirm
    @admin.update!(role: :admin)

    @member = User.create!(
      full_name:             "Investor",
      email:                 "investor@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @member.confirm

    create_all_six_plans
    @plan = InvestmentPlan.find_by(name: "Starter")

    @deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "sys_inv#{SecureRandom.hex(26)}",
      submitted_at:     Time.current
    )
    @deposit.approve!(reviewer: @admin)
    @deposit.reload
    @investment = @deposit.investment
  end

  test "member can visit investments index" do
    login_as @member
    visit investments_path
    assert_current_path investments_path
    assert_text "My Investments"
  end

  test "member sees their investment on the index" do
    login_as @member
    visit investments_path
    assert_text "Starter"
    assert_text "$500.00"
    assert_text "Active"
  end

  test "member can view investment show page" do
    login_as @member
    visit investment_path(@investment)
    assert_text "Investment ##{@investment.id}"
    assert_text "Starter"
    assert_text "$500.00"
    assert_text "Active"
    assert_text "14 Days"
  end

  test "investment show page links to the deposit" do
    login_as @member
    visit investment_path(@investment)
    assert_selector "a[href='#{deposit_path(@deposit)}']"
  end

  test "My Investments nav link is visible to authenticated users" do
    login_as @member
    visit authenticated_root_path
    assert_selector "a[href='#{investments_path}']"
  end

  test "unauthenticated user is redirected from investments" do
    visit investments_path
    assert_current_path new_user_session_path
  end

  test "approving a deposit creates an investment visible to the member" do
    new_deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00500000,
      transaction_hash: "sys_new#{SecureRandom.hex(25)}",
      submitted_at:     Time.current
    )

    login_as @admin
    visit admin_deposit_path(new_deposit)
    click_button "Approve Deposit"
    assert_text "Deposit approved successfully"

    login_as @member
    visit investments_path
    assert_equal 2, @member.investments.count
  end
end
