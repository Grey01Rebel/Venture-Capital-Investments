require "test_helper"

class DepositReviewTest < ActiveSupport::TestCase
  def setup
    @member   = create_confirmed_user
    @admin    = create_confirmed_user
    @admin.update!(role: :admin)
    @plan     = create_investment_plan(position: 701)
    @deposit  = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "rev#{SecureRandom.hex(30)}",
      submitted_at:     Time.current
    )
  end

  # approve!
  test "approve! sets status to approved" do
    @deposit.approve!(reviewer: @admin)
    assert @deposit.approved?
  end

  test "approve! sets approved_at" do
    @deposit.approve!(reviewer: @admin)
    assert_not_nil @deposit.approved_at
  end

  test "approve! sets reviewer" do
    @deposit.approve!(reviewer: @admin)
    assert_equal @admin, @deposit.reviewer
  end

  test "approve! sets admin_notes when provided" do
    @deposit.approve!(reviewer: @admin, notes: "Verified on chain.")
    assert_equal "Verified on chain.", @deposit.admin_notes
  end

  test "approve! admin_notes is nil when not provided" do
    @deposit.approve!(reviewer: @admin)
    assert_nil @deposit.admin_notes
  end

  test "approve! returns false on already approved deposit" do
    @deposit.approve!(reviewer: @admin)
    result = @deposit.approve!(reviewer: @admin)
    assert_equal false, result
  end

  test "approve! returns false on rejected deposit" do
    @deposit.reject!(reviewer: @admin)
    result = @deposit.approve!(reviewer: @admin)
    assert_equal false, result
  end

  test "approve! does not change status of already approved deposit" do
    @deposit.approve!(reviewer: @admin)
    @deposit.approve!(reviewer: @admin)
    assert @deposit.approved?
  end

  # reject!
  test "reject! sets status to rejected" do
    @deposit.reject!(reviewer: @admin)
    assert @deposit.rejected?
  end

  test "reject! sets rejected_at" do
    @deposit.reject!(reviewer: @admin)
    assert_not_nil @deposit.rejected_at
  end

  test "reject! sets reviewer" do
    @deposit.reject!(reviewer: @admin)
    assert_equal @admin, @deposit.reviewer
  end

  test "reject! sets admin_notes when provided" do
    @deposit.reject!(reviewer: @admin, notes: "Hash not found.")
    assert_equal "Hash not found.", @deposit.admin_notes
  end

  test "reject! returns false on already rejected deposit" do
    @deposit.reject!(reviewer: @admin)
    result = @deposit.reject!(reviewer: @admin)
    assert_equal false, result
  end

  test "reject! returns false on approved deposit" do
    @deposit.approve!(reviewer: @admin)
    result = @deposit.reject!(reviewer: @admin)
    assert_equal false, result
  end

  # Reviewer relationship
  test "deposit belongs to reviewer after review" do
    @deposit.approve!(reviewer: @admin)
    assert_equal @admin, @deposit.reviewer
  end

  test "reviewed_deposits association returns deposits reviewed by admin" do
    @deposit.approve!(reviewer: @admin)
    assert_includes @admin.reviewed_deposits, @deposit
  end

  test "nullifying reviewer does not destroy the deposit" do
    @deposit.approve!(reviewer: @admin)
    deposit_id = @deposit.id
    @admin.destroy
    assert_not_nil Deposit.find_by(id: deposit_id)
    assert_nil Deposit.find(deposit_id).reviewed_by_id
  end
end