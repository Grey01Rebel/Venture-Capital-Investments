# frozen_string_literal: true

require "test_helper"

class ProfitsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @member = create_confirmed_user
    @other  = create_confirmed_user

    @member_plan = create_investment_plan(
      position:              1801,
      investment_amount_usd: 500.00,
      daily_return_rate:     0.80
    )
    @other_plan = create_investment_plan(
      position:              1802,
      investment_amount_usd: 1000.00,
      daily_return_rate:     0.90
    )

    @member_investment = build_investment(@member, @member_plan, "pctrl1")
    @other_investment  = build_investment(@other,  @other_plan,  "pctrl2")

    @member_record = ProfitRecord.create!(
      user:        @member,
      investment:  @member_investment,
      amount:      4.00,
      profit_date: Date.current
    )

    @other_record = ProfitRecord.create!(
      user:        @other,
      investment:  @other_investment,
      amount:      9.99,
      profit_date: Date.current
    )
  end

  def build_investment(user, plan, hash_prefix)
    deposit = Deposit.create!(
      user:             user,
      investment_plan:  plan,
      amount_usd:       plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "#{hash_prefix}#{SecureRandom.hex(26)}",
      submitted_at:     Time.current
    )
    DepositReviewService.new(deposit: deposit, action: :approve, reviewer: @admin).call
    deposit.reload
    deposit.investment
  end

  # --- authenticated access ---

  test "authenticated member can access profits index" do
    sign_in @member
    get profits_path
    assert_response :success
  end

  test "authenticated admin can access profits index" do
    sign_in @admin
    get profits_path
    assert_response :success
  end

  # --- unauthenticated redirect ---

  test "unauthenticated user is redirected from profits index" do
    get profits_path
    assert_redirected_to new_user_session_path
  end

  # --- policy scope enforced ---

  test "member only sees their own profit records" do
    sign_in @member
    get profits_path
    assert_match @member_plan.name, response.body
    assert_no_match "$9.99", response.body
  end

  test "member's response does not include other user's plan name" do
    sign_in @member
    get profits_path
    assert_select "td", text: @other_plan.name, count: 0
  end

  test "admin sees all profit records" do
    sign_in @admin
    get profits_path
    assert_match "$4.00", response.body
    assert_match "$9.99", response.body
  end

  test "profits index displays profit amount" do
    sign_in @member
    get profits_path
    assert_match number_to_currency(@member_record.amount, precision: 2), response.body
  end

  test "profits index displays plan name" do
    sign_in @member
    get profits_path
    assert_match @member_plan.name, response.body
  end

  test "profits index displays investment status" do
    sign_in @member
    get profits_path
    assert_match "Active", response.body
  end

  test "profits index shows empty state when user has no records" do
    new_member = create_confirmed_user
    sign_in new_member
    get profits_path
    assert_match "No profit records yet.", response.body
  end

  private

  def number_to_currency(amount, precision:)
    ActionController::Base.helpers.number_to_currency(amount, precision: precision)
  end
end