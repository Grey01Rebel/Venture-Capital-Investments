# frozen_string_literal: true
require "test_helper"

class DepositSearchScopeTest < ActiveSupport::TestCase
  def setup
    @admin = create_confirmed_user
    @admin.update!(role: :admin)

    @alice = create_confirmed_user
    @alice.update!(full_name: "Alice Smith")

    @bob = create_confirmed_user
    @bob.update!(full_name: "Bob Jones")

    @plan = create_investment_plan(position: 8801)

    @alice_deposit = Deposit.create!(
      user: @alice, investment_plan: @plan,
      amount_usd: @plan.investment_amount_usd,
      btc_amount: 0.001,
      transaction_hash: "alicehash#{SecureRandom.hex(24)}",
      submitted_at: Time.current
    )

    @bob_deposit = Deposit.create!(
      user: @bob, investment_plan: @plan,
      amount_usd: @plan.investment_amount_usd,
      btc_amount: 0.001,
      transaction_hash: "bobhash#{SecureRandom.hex(26)}",
      submitted_at: Time.current
    )
  end

  test "blank search returns all deposits" do
    results = Deposit.search_by_term("")
    assert_includes results, @alice_deposit
    assert_includes results, @bob_deposit
  end

  test "nil search returns all deposits" do
    results = Deposit.search_by_term(nil)
    assert_includes results, @alice_deposit
    assert_includes results, @bob_deposit
  end

  test "searches by user full name" do
    results = Deposit.search_by_term("Alice")
    assert_includes     results, @alice_deposit
    assert_not_includes results, @bob_deposit
  end

  test "search is case-insensitive" do
    results = Deposit.search_by_term("alice")
    assert_includes results, @alice_deposit
  end

  test "searches by transaction hash" do
    results = Deposit.search_by_term("alicehash")
    assert_includes     results, @alice_deposit
    assert_not_includes results, @bob_deposit
  end

  test "no results for unmatched search" do
    results = Deposit.search_by_term("zzznomatch999")
    assert_empty results
  end
end
