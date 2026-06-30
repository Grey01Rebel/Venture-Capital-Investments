require "test_helper"

class WithdrawalTest < ActiveSupport::TestCase
  def setup
    @user = create_confirmed_user
  end

  def valid_attributes
    {
      user:        @user,
      amount:      0.05000000,
      btc_address: "bc1qxyz1234567890abcdefghijklmnopqrstuv",
      status:      :pending
    }
  end

  # --- valid record ---

  test "creates a valid withdrawals with all required attributes" do
    withdrawal = Withdrawal.new(valid_attributes)
    assert withdrawal.valid?, "Expected withdrawals to be valid: #{withdrawal.errors.full_messages}"
  end

  # --- amount validations ---

  test "is invalid without an amount" do
    withdrawal = Withdrawal.new(valid_attributes.merge(amount: nil))
    assert_not withdrawal.valid?
    assert withdrawal.errors[:amount].any?
  end

  test "is invalid when amount is zero" do
    withdrawal = Withdrawal.new(valid_attributes.merge(amount: 0))
    assert_not withdrawal.valid?
    assert withdrawal.errors[:amount].any?
  end

  test "is invalid when amount is negative" do
    withdrawal = Withdrawal.new(valid_attributes.merge(amount: -0.01))
    assert_not withdrawal.valid?
    assert withdrawal.errors[:amount].any?
  end

  test "is valid with a small positive amount" do
    withdrawal = Withdrawal.new(valid_attributes.merge(amount: 0.00000001))
    assert withdrawal.valid?
  end

  # --- btc_address validations ---

  test "is invalid without a btc_address" do
    withdrawal = Withdrawal.new(valid_attributes.merge(btc_address: nil))
    assert_not withdrawal.valid?
    assert withdrawal.errors[:btc_address].any?
  end

  test "is invalid with a blank btc_address" do
    withdrawal = Withdrawal.new(valid_attributes.merge(btc_address: ""))
    assert_not withdrawal.valid?
    assert withdrawal.errors[:btc_address].any?
  end

  # --- status ---

  test "defaults to pending status" do
    withdrawal = Withdrawal.create!(valid_attributes.except(:status))
    assert withdrawal.pending?
  end

  test "is invalid without a status" do
    withdrawal = Withdrawal.new(valid_attributes)
    withdrawal.status = nil
    assert_not withdrawal.valid?
  end

  test "supports all four status values" do
    %i[pending approved rejected].each do |status_value|
      withdrawal = Withdrawal.create!(valid_attributes.merge(status: status_value))
      assert_equal status_value.to_s, withdrawal.status
    end

    completed = Withdrawal.create!(valid_attributes.merge(
      status:           :completed,
      transaction_hash: "tx_#{SecureRandom.hex(16)}"
    ))
    assert_equal "completed", completed.status
  end

  # --- associations ---

  test "belongs to a user" do
    withdrawal = Withdrawal.create!(valid_attributes)
    assert_equal @user, withdrawal.user
  end

  test "is invalid without a user" do
    withdrawal = Withdrawal.new(valid_attributes.merge(user: nil))
    assert_not withdrawal.valid?
  end

  test "reviewer is optional" do
    withdrawal = Withdrawal.new(valid_attributes)
    assert_nil withdrawal.reviewer
    assert withdrawal.valid?
  end

  test "can be assigned a reviewer" do
    admin = create_confirmed_user
    admin.update!(role: :admin)
    withdrawal = Withdrawal.create!(valid_attributes.merge(reviewer: admin))
    assert_equal admin, withdrawal.reviewer
  end

  # --- user association ---

  test "user has many withdrawals" do
    withdrawal = Withdrawal.create!(valid_attributes)
    assert_includes @user.withdrawals, withdrawal
  end

  test "cannot destroy user with existing withdrawals" do
    Withdrawal.create!(valid_attributes)
    assert_raises(ActiveRecord::DeleteRestrictionError) do
      @user.destroy
    end
  end

  # --- timestamps remain nil until set ---

  test "approved_at is nil by default" do
    withdrawal = Withdrawal.create!(valid_attributes)
    assert_nil withdrawal.approved_at
  end

  test "rejected_at is nil by default" do
    withdrawal = Withdrawal.create!(valid_attributes)
    assert_nil withdrawal.rejected_at
  end

  test "completed_at is nil by default" do
    withdrawal = Withdrawal.create!(valid_attributes)
    assert_nil withdrawal.completed_at
  end
end