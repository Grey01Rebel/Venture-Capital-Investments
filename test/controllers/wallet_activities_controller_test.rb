# frozen_string_literal: true
require "test_helper"

class WalletActivitiesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @member = create_confirmed_user
    @other  = create_confirmed_user
    @plan   = create_investment_plan(
      position:              2101,
      investment_amount_usd: 500.00,
      daily_return_rate:     0.80
    )
  end

  def build_investment(user, hash_prefix)
    deposit = Deposit.create!(
      user:             user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "#{hash_prefix}#{SecureRandom.hex(26)}",
      submitted_at:     Time.current
    )
    deposit.approve!(reviewer: @admin)
    deposit.reload
    deposit.investment
  end

  # --- authenticated access ---

  test "authenticated user can access wallet activity index" do
    sign_in @member
    get wallet_activity_path
    assert_response :success
  end

  # --- unauthenticated redirect ---

  test "unauthenticated user is redirected from wallet activity index" do
    get wallet_activity_path
    assert_redirected_to new_user_session_path
  end

  # --- user only sees own activity ---

  test "user only sees their own profit credit activity" do
    member_investment = build_investment(@member, "wact1")
    other_investment  = build_investment(@other,   "wact2")

    ProfitRecord.create!(
      user:        @member,
      investment:  member_investment,
      amount:      4.00,
      profit_date: Date.current
    )
    ProfitRecord.create!(
      user:        @other,
      investment:  other_investment,
      amount:      9.99,
      profit_date: Date.current
    )

    sign_in @member
    get wallet_activity_path
    assert_match "$4.00", response.body
    assert_no_match "$9.99", response.body
  end

  test "user only sees their own principal return activity" do
    member_investment = build_investment(@member, "wact3")
    other_investment  = build_investment(@other,   "wact4")
    member_investment.update!(status: :completed, completed_at: Time.current)
    other_investment.update!(status: :completed, completed_at: Time.current)

    sign_in @member
    get wallet_activity_path
    assert_match "Principal Return", response.body
    assert_select "table tbody tr", count: 1
  end

  test "admin only sees their own wallet activity, not all users'" do
    admin_investment  = build_investment(@admin, "wact5")
    member_investment = build_investment(@member, "wact6")

    ProfitRecord.create!(
      user:        @admin,
      investment:  admin_investment,
      amount:      2.50,
      profit_date: Date.current
    )
    ProfitRecord.create!(
      user:        @member,
      investment:  member_investment,
      amount:      7.77,
      profit_date: Date.current
    )

    sign_in @admin
    get wallet_activity_path
    assert_match "$2.50", response.body
    assert_no_match "$7.77", response.body
  end

  # --- display content ---

  test "wallet activity displays profit credit type" do
    investment = build_investment(@member, "wact7")
    ProfitRecord.create!(
      user:        @member,
      investment:  investment,
      amount:      4.00,
      profit_date: Date.current
    )

    sign_in @member
    get wallet_activity_path
    assert_match "Profit Credit", response.body
  end

  test "wallet activity displays principal return type" do
    investment = build_investment(@member, "wact8")
    investment.update!(status: :completed, completed_at: Time.current)

    sign_in @member
    get wallet_activity_path
    assert_match "Principal Return", response.body
  end

  test "wallet activity shows empty state when user has no activity" do
    sign_in @member
    get wallet_activity_path
    assert_match "No wallet activity yet.", response.body
  end
end
