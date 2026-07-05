# frozen_string_literal: true
require "test_helper"

class WithdrawalSearchScopeTest < ActiveSupport::TestCase
  def setup
    @alice = create_confirmed_user
    @alice.update!(full_name: "Alice Smith")
    @alice.wallet.update!(available_balance: 0.10)

    @bob = create_confirmed_user
    @bob.update!(full_name: "Bob Jones")
    @bob.wallet.update!(available_balance: 0.10)

    @alice_withdrawal = Withdrawal.create!(
      user: @alice, amount: 0.01,
      btc_address: "bc1qalice123",
      status: :pending, requested_at: Time.current
    )

    @bob_withdrawal = Withdrawal.create!(
      user: @bob, amount: 0.01,
      btc_address: "bc1qbob456",
      status: :pending, requested_at: Time.current
    )
  end

  test "blank search returns all withdrawals" do
    results = Withdrawal.search_by_term("")
    assert_includes results, @alice_withdrawal
    assert_includes results, @bob_withdrawal
  end

  test "searches by user full name" do
    results = Withdrawal.search_by_term("Alice")
    assert_includes     results, @alice_withdrawal
    assert_not_includes results, @bob_withdrawal
  end

  test "searches by BTC address" do
    results = Withdrawal.search_by_term("bc1qalice")
    assert_includes     results, @alice_withdrawal
    assert_not_includes results, @bob_withdrawal
  end

  test "search is case-insensitive" do
    results = Withdrawal.search_by_term("alice")
    assert_includes results, @alice_withdrawal
  end

  test "no results for unmatched search" do
    results = Withdrawal.search_by_term("zzznomatch")
    assert_empty results
  end
end
