require "test_helper"

class WithdrawalPolicyTest < ActiveSupport::TestCase
  def setup
    @member = create_confirmed_user
    @other  = create_confirmed_user
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)

    @member_withdrawal = Withdrawal.create!(
      user:         @member,
      amount:       0.02000000,
      btc_address:  "bc1qmember",
      status:       :pending,
      requested_at: Time.current
    )

    @other_withdrawal = Withdrawal.create!(
      user:         @other,
      amount:       0.03000000,
      btc_address:  "bc1qother",
      status:       :pending,
      requested_at: Time.current
    )
  end

  test "member can access withdrawal index"  do
    assert WithdrawalPolicy.new(@member, Withdrawal).index?
  end

  test "admin can access withdrawal index" do
    assert WithdrawalPolicy.new(@admin, Withdrawal).index?
  end

  test "member can view their own withdrawal" do
    assert WithdrawalPolicy.new(@member, @member_withdrawal).show?
  end

  test "member cannot view another member's withdrawal" do
    assert_not WithdrawalPolicy.new(@member, @other_withdrawal).show?
  end

  test "admin can view any withdrawal" do
    assert WithdrawalPolicy.new(@admin, @member_withdrawal).show?
    assert WithdrawalPolicy.new(@admin, @other_withdrawal).show?
  end

  test "admin can approve a withdrawal" do
    assert WithdrawalPolicy.new(@admin, @member_withdrawal).approve?
  end

  test "member cannot approve a withdrawal" do
    assert_not WithdrawalPolicy.new(@member, @member_withdrawal).approve?
  end

  test "admin can reject a withdrawal" do
    assert WithdrawalPolicy.new(@admin, @member_withdrawal).reject?
  end

  test "member cannot reject a withdrawal" do
    assert_not WithdrawalPolicy.new(@member, @member_withdrawal).reject?
  end

  test "admin can complete a withdrawal" do
    assert WithdrawalPolicy.new(@admin, @member_withdrawal).complete?
  end

  test "member cannot complete a withdrawal" do
    assert_not WithdrawalPolicy.new(@member, @member_withdrawal).complete?
  end

  test "policy scope for member returns only their own withdrawals" do
    scope   = WithdrawalPolicy::Scope.new(@member, Withdrawal.all)
    results = scope.resolve
    assert_includes     results, @member_withdrawal
    assert_not_includes results, @other_withdrawal
  end

  test "policy scope for admin returns all withdrawals" do
    scope   = WithdrawalPolicy::Scope.new(@admin, Withdrawal.all)
    results = scope.resolve
    assert_includes results, @member_withdrawal
    assert_includes results, @other_withdrawal
  end

  test "unauthenticated access raises NotAuthorizedError" do
    assert_raises(Pundit::NotAuthorizedError) do
      WithdrawalPolicy.new(nil, Withdrawal)
    end
  end
end