# frozen_string_literal: true
require "test_helper"

class InvestmentTest < ActiveSupport::TestCase
  def setup
    @user   = create_confirmed_user
    @plan   = create_investment_plan(position: 901)
    @deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "inv#{SecureRandom.hex(30)}",
      submitted_at:     Time.current
    )
  end

  def valid_attributes
    {
      user:             @user,
      deposit:          @deposit,
      investment_plan:  @plan,
      principal_amount: 1_000.00,
      daily_return_rate: 1.00,
      duration_days:    14,
      started_at:       Time.current,
      ends_at:          14.days.from_now
    }
  end

  # Valid investment creation
  test "creates a valid investment with all required attributes" do
    investment = Investment.new(valid_attributes)
    assert investment.valid?, "Expected investment to be valid: #{investment.errors.full_messages}"
  end

  # Default status
  test "default status is active" do
    investment = Investment.create!(valid_attributes)
    assert investment.active?
    assert_equal "active", investment.status
  end

  # Enum behaviour
  test "status enum includes active and completed" do
    investment = Investment.create!(valid_attributes)
    assert investment.active?
    investment.update!(status: :completed)
    assert investment.completed?
  end

  test "active? returns true for active investments" do
    investment = Investment.create!(valid_attributes)
    assert investment.active?
  end

  test "completed? returns true for completed investments" do
    investment = Investment.create!(valid_attributes)
    investment.update!(status: :completed)
    assert investment.completed?
  end

  # complete! behaviour
  test "complete! sets status to completed" do
    investment = Investment.create!(valid_attributes)
    investment.complete!
    assert investment.completed?
  end

  test "complete! returns false when already completed" do
    investment = Investment.create!(valid_attributes)
    investment.complete!
    result = investment.complete!
    assert_equal false, result
  end

  test "complete! is safe to call multiple times" do
    investment = Investment.create!(valid_attributes)
    3.times { investment.complete! }
    assert investment.completed?
  end

  test "complete! does not change ends_at or other fields" do
    investment = Investment.create!(valid_attributes)
    original_ends_at = investment.ends_at
    investment.complete!
    assert_equal original_ends_at, investment.reload.ends_at
  end

  # deposit_id uniqueness
  test "is invalid with a duplicate deposit" do
    Investment.create!(valid_attributes)
    duplicate = Investment.new(valid_attributes)
    assert_not duplicate.valid?
    assert duplicate.errors[:deposit_id].any?
  end

  test "one deposit cannot have two investments" do
    Investment.create!(valid_attributes)
    assert_raises(ActiveRecord::RecordNotUnique) do
      Investment.connection.execute(
        "INSERT INTO investments (user_id, deposit_id, investment_plan_id,
         principal_amount, daily_return_rate, duration_days,
         started_at, ends_at, status, created_at, updated_at)
         VALUES (#{@user.id}, #{@deposit.id}, #{@plan.id},
         1000.00, 1.00, 14,
         NOW(), NOW() + INTERVAL '14 days', 0, NOW(), NOW())"
      )
    end
  end

  # principal_amount validations
  test "is invalid when principal_amount is zero" do
    investment = Investment.new(valid_attributes.merge(principal_amount: 0))
    assert_not investment.valid?
    assert investment.errors[:principal_amount].any?
  end

  test "is invalid when principal_amount is negative" do
    investment = Investment.new(valid_attributes.merge(principal_amount: -100))
    assert_not investment.valid?
    assert investment.errors[:principal_amount].any?
  end

  test "is invalid without principal_amount" do
    investment = Investment.new(valid_attributes.merge(principal_amount: nil))
    assert_not investment.valid?
    assert investment.errors[:principal_amount].any?
  end

  # daily_return_rate validations
  test "is invalid when daily_return_rate is zero" do
    investment = Investment.new(valid_attributes.merge(daily_return_rate: 0))
    assert_not investment.valid?
    assert investment.errors[:daily_return_rate].any?
  end

  test "is invalid when daily_return_rate is negative" do
    investment = Investment.new(valid_attributes.merge(daily_return_rate: -1))
    assert_not investment.valid?
    assert investment.errors[:daily_return_rate].any?
  end

  test "is invalid without daily_return_rate" do
    investment = Investment.new(valid_attributes.merge(daily_return_rate: nil))
    assert_not investment.valid?
    assert investment.errors[:daily_return_rate].any?
  end

  # duration_days validations
  test "is invalid when duration_days is zero" do
    investment = Investment.new(valid_attributes.merge(duration_days: 0))
    assert_not investment.valid?
    assert investment.errors[:duration_days].any?
  end

  test "is invalid when duration_days is negative" do
    investment = Investment.new(valid_attributes.merge(duration_days: -7))
    assert_not investment.valid?
    assert investment.errors[:duration_days].any?
  end

  test "is invalid without duration_days" do
    investment = Investment.new(valid_attributes.merge(duration_days: nil))
    assert_not investment.valid?
    assert investment.errors[:duration_days].any?
  end

  # started_at / ends_at
  test "is invalid without started_at" do
    investment = Investment.new(valid_attributes.merge(started_at: nil))
    assert_not investment.valid?
    assert investment.errors[:started_at].any?
  end

  test "is invalid without ends_at" do
    investment = Investment.new(valid_attributes.merge(ends_at: nil))
    assert_not investment.valid?
    assert investment.errors[:ends_at].any?
  end

  # Relationship tests
  test "belongs to a user" do
    investment = Investment.create!(valid_attributes)
    assert_equal @user, investment.user
  end

  test "belongs to a deposit" do
    investment = Investment.create!(valid_attributes)
    assert_equal @deposit, investment.deposit
  end

  test "belongs to an investment plan" do
    investment = Investment.create!(valid_attributes)
    assert_equal @plan, investment.investment_plan
  end

  test "user has many investments" do
    Investment.create!(valid_attributes)
    assert_includes @user.investments, Investment.last
  end

  test "cannot destroy deposit with an existing investment" do
    Investment.create!(valid_attributes)
    assert_raises(ActiveRecord::DeleteRestrictionError) do
      @deposit.destroy
    end
  end

  test "cannot destroy investment plan with existing investments" do
    Investment.create!(valid_attributes)
    assert_raises(ActiveRecord::DeleteRestrictionError) do
      @plan.destroy
    end
  end

  test "cannot destroy user with existing investments" do
    Investment.create!(valid_attributes)
    assert_raises(ActiveRecord::DeleteRestrictionError) do
      @user.destroy
    end
  end
end
