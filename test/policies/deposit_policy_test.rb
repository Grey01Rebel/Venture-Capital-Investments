require "test_helper"

class DepositPolicyTest < ActiveSupport::TestCase
  def setup
    @user       = create_confirmed_user
    @other_user = create_confirmed_user
    @plan       = create_investment_plan(position: 501)

    @own_deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       500.00,
      btc_amount:       0.00812345,
      transaction_hash: "own#{SecureRandom.hex(29)}",
      submitted_at:     Time.current
    )

    @other_deposit = Deposit.create!(
      user:             @other_user,
      investment_plan:  @plan,
      amount_usd:       500.00,
      btc_amount:       0.00812345,
      transaction_hash: "other#{SecureRandom.hex(27)}",
      submitted_at:     Time.current
    )
  end

  test "user can access deposit index" do
    policy = DepositPolicy.new(@user, Deposit)
    assert policy.index?
  end

  test "user can view their own deposit" do
    policy = DepositPolicy.new(@user, @own_deposit)
    assert policy.show?
  end

  test "user cannot view another user's deposit" do
    policy = DepositPolicy.new(@user, @other_deposit)
    assert_not policy.show?
  end

  test "user can access new deposit form" do
    policy = DepositPolicy.new(@user, Deposit)
    assert policy.new?
  end

  test "user can create a deposit" do
    policy = DepositPolicy.new(@user, Deposit)
    assert policy.create?
  end

  test "unauthenticated access raises NotAuthorizedError" do
    assert_raises(Pundit::NotAuthorizedError) do
      DepositPolicy.new(nil, Deposit)
    end
  end

  test "policy scope returns only the current user's deposits" do
    scope   = DepositPolicy::Scope.new(@user, Deposit.all)
    results = scope.resolve
    assert_includes     results, @own_deposit
    assert_not_includes results, @other_deposit
  end

  test "policy scope for other user returns only their deposits" do
    scope   = DepositPolicy::Scope.new(@other_user, Deposit.all)
    results = scope.resolve
    assert_includes     results, @other_deposit
    assert_not_includes results, @own_deposit
  end

  test "policy scope raises NotAuthorizedError for unauthenticated user" do
    assert_raises(Pundit::NotAuthorizedError) do
      DepositPolicy::Scope.new(nil, Deposit.all)
    end
  end
end