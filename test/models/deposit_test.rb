require "test_helper"

class DepositTest < ActiveSupport::TestCase
  def setup
    @user = create_confirmed_user
    @plan = create_investment_plan(
      investment_amount_usd: 500.00,
      position: 401
    )
  end

  def valid_attributes
    {
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       500.00,
      btc_amount:       0.00812345,
      transaction_hash: "abc#{SecureRandom.hex(30)}",
      submitted_at:     Time.current
    }
  end

  # Valid deposit creation
  test "creates a valid deposit with all required attributes" do
    deposit = Deposit.new(valid_attributes)
    assert deposit.valid?, "Expected deposit to be valid: #{deposit.errors.full_messages}"
  end

  # Default status is pending
  test "default status is pending" do
    deposit = Deposit.create!(valid_attributes)
    assert deposit.pending?
    assert_equal "pending", deposit.status
  end

  test "status enum includes pending, approved, and rejected" do
    deposit = Deposit.create!(valid_attributes)
    deposit.approved!
    assert deposit.approved?
    deposit.rejected!
    assert deposit.rejected?
  end

  # transaction_hash required
  test "is invalid without a transaction_hash" do
    deposit = Deposit.new(valid_attributes.merge(transaction_hash: ""))
    assert_not deposit.valid?
    assert_includes deposit.errors[:transaction_hash], "can't be blank"
  end

  # transaction_hash unique
  test "is invalid with a duplicate transaction_hash" do
    hash = "unique#{SecureRandom.hex(28)}"
    Deposit.create!(valid_attributes.merge(transaction_hash: hash))
    duplicate = Deposit.new(valid_attributes.merge(transaction_hash: hash))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:transaction_hash], "has already been taken"
  end

  # amount_usd positive
  test "is invalid when amount_usd is zero" do
    deposit = Deposit.new(valid_attributes.merge(amount_usd: 0))
    assert_not deposit.valid?
    assert deposit.errors[:amount_usd].any?
  end

  test "is invalid when amount_usd is negative" do
    deposit = Deposit.new(valid_attributes.merge(amount_usd: -100))
    assert_not deposit.valid?
    assert deposit.errors[:amount_usd].any?
  end

  test "is invalid without amount_usd" do
    deposit = Deposit.new(valid_attributes.merge(amount_usd: nil))
    assert_not deposit.valid?
    assert deposit.errors[:amount_usd].any?
  end

  # btc_amount positive
  test "is invalid when btc_amount is zero" do
    deposit = Deposit.new(valid_attributes.merge(btc_amount: 0))
    assert_not deposit.valid?
    assert deposit.errors[:btc_amount].any?
  end

  test "is invalid when btc_amount is negative" do
    deposit = Deposit.new(valid_attributes.merge(btc_amount: -0.001))
    assert_not deposit.valid?
    assert deposit.errors[:btc_amount].any?
  end

  test "is invalid without btc_amount" do
    deposit = Deposit.new(valid_attributes.merge(btc_amount: nil))
    assert_not deposit.valid?
    assert deposit.errors[:btc_amount].any?
  end

  # submitted_at required
  test "is invalid without submitted_at" do
    deposit = Deposit.new(valid_attributes.merge(submitted_at: nil))
    assert_not deposit.valid?
    assert deposit.errors[:submitted_at].any?
  end

  # associations
  test "belongs to a user" do
    deposit = Deposit.create!(valid_attributes)
    assert_equal @user, deposit.user
  end

  test "belongs to an investment plan" do
    deposit = Deposit.create!(valid_attributes)
    assert_equal @plan, deposit.investment_plan
  end

  test "user has many deposits" do
    Deposit.create!(valid_attributes)
    Deposit.create!(valid_attributes.merge(transaction_hash: "other#{SecureRandom.hex(28)}"))
    assert_equal 2, @user.deposits.count
  end

  test "destroying user destroys their deposits" do
    deposit = Deposit.create!(valid_attributes)
    deposit_id = deposit.id
    @user.destroy
    assert_nil Deposit.find_by(id: deposit_id)
  end

  test "cannot destroy investment plan with existing deposits" do
    Deposit.create!(valid_attributes)
    assert_raises(ActiveRecord::DeleteRestrictionError) do
      @plan.destroy
    end
  end
end