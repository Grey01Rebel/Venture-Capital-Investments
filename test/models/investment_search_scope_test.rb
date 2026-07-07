# frozen_string_literal: true
require "test_helper"

class InvestmentSearchScopeTest < ActiveSupport::TestCase
  def setup
    @admin = create_confirmed_user
    @admin.update!(role: :admin)

    @alice = create_confirmed_user
    @alice.update!(full_name: "Alice Investor")

    @bob = create_confirmed_user
    @bob.update!(full_name: "Bob Trader")

    @starter_plan = create_investment_plan(position: 8901, investment_amount_usd: 500.00, daily_return_rate: 0.80)
    @gold_plan    = create_investment_plan(position: 8902, investment_amount_usd: 3000.00, daily_return_rate: 1.20)

    @alice_investment = build_investment(@alice, @starter_plan, "iss1")
    @bob_investment   = build_investment(@bob,   @gold_plan,    "iss2")
  end

  def build_investment(user, plan, prefix)
    deposit = Deposit.create!(
      user: user, investment_plan: plan,
      amount_usd: plan.investment_amount_usd, btc_amount: 0.001,
      transaction_hash: "#{prefix}#{SecureRandom.hex(28)}",
      submitted_at: Time.current
    )
    DepositReviewService.new(deposit: deposit, action: :approve, reviewer: @admin).call
    deposit.reload.investment
  end

  test "blank search returns all investments" do
    results = Investment.search_by_term("")
    assert_includes results, @alice_investment
    assert_includes results, @bob_investment
  end

  test "searches by user full name" do
    results = Investment.search_by_term("Alice")
    assert_includes     results, @alice_investment
    assert_not_includes results, @bob_investment
  end

  test "searches by plan name" do
    results = Investment.search_by_term(@starter_plan.name)
    assert_includes     results, @alice_investment
    assert_not_includes results, @bob_investment
  end

  test "search is case-insensitive" do
    results = Investment.search_by_term("alice")
    assert_includes results, @alice_investment
  end

  test "by_status scope filters active investments" do
    results = Investment.by_status("active")
    assert_includes results, @alice_investment
    assert_includes results, @bob_investment
  end

  test "by_status scope with blank returns all" do
    results = Investment.by_status("")
    assert_includes results, @alice_investment
    assert_includes results, @bob_investment
  end

  test "no results for unmatched search" do
    results = Investment.search_by_term("zzznomatch")
    assert_empty results
  end
end
