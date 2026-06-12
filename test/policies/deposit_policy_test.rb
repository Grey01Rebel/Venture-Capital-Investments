require "test_helper"

class DepositPolicyTest < ActiveSupport::TestCase
  def setup
    @member     = create_confirmed_user
    @other      = create_confirmed_user
    @admin      = create_confirmed_user
    @admin.update!(role: :admin)
    @plan       = create_investment_plan(position: 501)

    @member_deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       500.00,
      btc_amount:       0.00812345,
      transaction_hash: "own#{SecureRandom.hex(29)}",
      submitted_at:     Time.current
    )

    @other_deposit = Deposit.create!(
      user:             @other,
      investment_plan:  @plan,
      amount_usd:       500.00,
      btc_amount:       0.00812345,
      transaction_hash: "other#{SecureRandom.hex(27)}",
      submitted_at:     Time.current
    )
  end

  # index?
  test "member can access deposit index" do
    assert DepositPolicy.new(@member, Deposit).index?
  end

  test "admin can access deposit index" do
    assert DepositPolicy.new(@admin, Deposit).index?
  end

  # show?
  test "member can view their own deposit" do
    assert DepositPolicy.new(@member, @member_deposit).show?
  end

  test "member cannot view another member's deposit" do
    assert_not DepositPolicy.new(@member, @other_deposit).show?
  end

  test "admin can view any deposit" do
    assert DepositPolicy.new(@admin, @member_deposit).show?
    assert DepositPolicy.new(@admin, @other_deposit).show?
  end

  # new? / create?
  test "member can access new deposit form" do
    assert DepositPolicy.new(@member, Deposit).new?
  end

  test "member can create a deposit" do
    assert DepositPolicy.new(@member, Deposit).create?
  end

  # approve?
  test "admin can approve deposits" do
    assert DepositPolicy.new(@admin, @member_deposit).approve?
  end

  test "member cannot approve deposits" do
    assert_not DepositPolicy.new(@member, @member_deposit).approve?
  end

  # reject?
  test "admin can reject deposits" do
    assert DepositPolicy.new(@admin, @member_deposit).reject?
  end

  test "member cannot reject deposits" do
    assert_not DepositPolicy.new(@member, @member_deposit).reject?
  end

  # Scope — member
  test "policy scope for member returns only their deposits" do
    scope   = DepositPolicy::Scope.new(@member, Deposit.all)
    results = scope.resolve
    assert_includes     results, @member_deposit
    assert_not_includes results, @other_deposit
  end

  # Scope — admin
  test "policy scope for admin returns all deposits" do
    scope   = DepositPolicy::Scope.new(@admin, Deposit.all)
    results = scope.resolve
    assert_includes results, @member_deposit
    assert_includes results, @other_deposit
  end

  # Unauthenticated
  test "unauthenticated access raises NotAuthorizedError" do
    assert_raises(Pundit::NotAuthorizedError) do
      DepositPolicy.new(nil, Deposit)
    end
  end

  test "policy scope raises NotAuthorizedError for unauthenticated user" do
    assert_raises(Pundit::NotAuthorizedError) do
      DepositPolicy::Scope.new(nil, Deposit.all)
    end
  end
end