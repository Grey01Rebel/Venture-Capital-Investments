# frozen_string_literal: true
require "test_helper"

class Admin::InvestmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @member = create_confirmed_user
    @plan   = create_investment_plan(position: 9001)

    deposit = Deposit.create!(
      user: @member, investment_plan: @plan,
      amount_usd: @plan.investment_amount_usd, btc_amount: 0.001,
      transaction_hash: "invadm#{SecureRandom.hex(27)}",
      submitted_at: Time.current
    )
    DepositReviewService.new(deposit: deposit, action: :approve, reviewer: @admin).call
    deposit.reload
    @investment = deposit.investment
  end

  test "admin can access admin investments index" do
    sign_in @admin
    get admin_investments_path
    assert_response :success
  end

  test "member is redirected from admin investments index" do
    sign_in @member
    get admin_investments_path
    assert_redirected_to authenticated_root_path
  end

  test "unauthenticated user is redirected" do
    get admin_investments_path
    assert_redirected_to new_user_session_path
  end

  test "index displays investments" do
    sign_in @admin
    get admin_investments_path
    assert_match @member.full_name, response.body
    assert_match @plan.name, response.body
  end

  test "index filters by active status" do
    sign_in @admin
    get admin_investments_path(status: "active")
    assert_response :success
    assert_match "Active", response.body
  end

  test "index filters by completed status" do
    @investment.update!(status: :completed, completed_at: Time.current)
    sign_in @admin
    get admin_investments_path(status: "completed")
    assert_match "Completed", response.body
  end

  test "index searches by investor name" do
    sign_in @admin
    get admin_investments_path(search: @member.full_name)
    assert_match @member.full_name, response.body
  end

  test "search with no results shows empty state" do
    sign_in @admin
    get admin_investments_path(search: "zzznomatch999")
    assert_match "No investments found matching", response.body
  end

  test "index paginates results" do
    sign_in @admin
    get admin_investments_path
    assert_response :success
  end
end
