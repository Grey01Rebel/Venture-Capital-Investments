require "test_helper"

class InvestmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @member = create_confirmed_user
    @other  = create_confirmed_user
    @plan   = create_investment_plan(position: 1201)

    @member_deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "invct#{SecureRandom.hex(28)}",
      submitted_at:     Time.current
    )
    @member_deposit.approve!(reviewer: @admin)
    @member_deposit.reload
    @investment = @member_deposit.investment

    @other_deposit = Deposit.create!(
      user:             @other,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00500000,
      transaction_hash: "invct2#{SecureRandom.hex(27)}",
      submitted_at:     Time.current
    )
    @other_deposit.approve!(reviewer: @admin)
    @other_deposit.reload
    @other_investment = @other_deposit.investment
  end

  # --- index ---

  test "authenticated member can access investments index" do
    sign_in @member
    get investments_path
    assert_response :success
  end

  test "unauthenticated user is redirected from investments index" do
    get investments_path
    assert_redirected_to new_user_session_path
  end

  test "member only sees their own investments" do
    sign_in @member
    get investments_path
    assert_match @plan.name, response.body
    assert_no_match @other_deposit.transaction_hash, response.body
  end

  test "admin sees all investments" do
    sign_in @admin
    get investments_path
    assert_response :success
  end

  # --- show ---

  test "member can view their own investment" do
    sign_in @member
    get investment_path(@investment)
    assert_response :success
  end

  test "member cannot view another member's investment" do
    sign_in @member
    get investment_path(@other_investment)
    assert_response :redirect
  end

  test "unauthenticated user is redirected from investment show" do
    get investment_path(@investment)
    assert_redirected_to new_user_session_path
  end

  test "admin can view any investment" do
    sign_in @admin
    get investment_path(@investment)
    assert_response :success
    get investment_path(@other_investment)
    assert_response :success
  end

  test "investment show displays plan name" do
    sign_in @member
    get investment_path(@investment)
    assert_match @plan.name, response.body
  end

  test "investment show displays principal amount" do
    sign_in @member
    get investment_path(@investment)
    assert_match number_to_currency(@investment.principal_amount), response.body
  end

  test "investment show displays status" do
    sign_in @member
    get investment_path(@investment)
    assert_match "Active", response.body
  end

  private

  def number_to_currency(amount)
    ActionController::Base.helpers.number_to_currency(amount, precision: 2)
  end
end