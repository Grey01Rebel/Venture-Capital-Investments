require "test_helper"

class ProfitRecordTest < ActiveSupport::TestCase
  def setup
    @user    = create_confirmed_user
    @plan    = create_investment_plan(position: 1301)
    @deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "pr#{SecureRandom.hex(30)}",
      submitted_at:     Time.current
    )
    @investment = Investment.create!(
      user:              @user,
      deposit:           @deposit,
      investment_plan:   @plan,
      principal_amount:  @plan.investment_amount_usd,
      daily_return_rate: @plan.daily_return_rate,
      duration_days:     @plan.duration_days,
      started_at:        Time.current,
      ends_at:           14.days.from_now
    )
  end

  def valid_attributes
    {
      user:        @user,
      investment:  @investment,
      amount:      4.00,
      profit_date: Date.current
    }
  end

  # Valid profit record
  test "creates a valid profit record with all required attributes" do
    record = ProfitRecord.new(valid_attributes)
    assert record.valid?, "Expected record to be valid: #{record.errors.full_messages}"
  end

  # amount validation
  test "is invalid when amount is zero" do
    record = ProfitRecord.new(valid_attributes.merge(amount: 0))
    assert_not record.valid?
    assert record.errors[:amount].any?
  end

  test "is invalid when amount is negative" do
    record = ProfitRecord.new(valid_attributes.merge(amount: -5))
    assert_not record.valid?
    assert record.errors[:amount].any?
  end

  test "is invalid without amount" do
    record = ProfitRecord.new(valid_attributes.merge(amount: nil))
    assert_not record.valid?
    assert record.errors[:amount].any?
  end

  # profit_date validation
  test "is invalid without profit_date" do
    record = ProfitRecord.new(valid_attributes.merge(profit_date: nil))
    assert_not record.valid?
    assert record.errors[:profit_date].any?
  end

  # user_id / investment_id presence
  test "is invalid without a user" do
    record = ProfitRecord.new(valid_attributes.merge(user: nil))
    assert_not record.valid?
  end

  test "is invalid without an investment" do
    record = ProfitRecord.new(valid_attributes.merge(investment: nil))
    assert_not record.valid?
  end

  # unique investment/date constraint
  test "is invalid with a duplicate investment and profit_date combination" do
    ProfitRecord.create!(valid_attributes)
    duplicate = ProfitRecord.new(valid_attributes)
    assert_not duplicate.valid?
    assert duplicate.errors[:investment_id].any?
  end

  test "allows the same investment to have profit records on different dates" do
    ProfitRecord.create!(valid_attributes)
    next_day = ProfitRecord.new(valid_attributes.merge(profit_date: Date.current + 1))
    assert next_day.valid?
  end

  test "allows different investments to have profit records on the same date" do
    other_deposit = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00500000,
      transaction_hash: "pr2#{SecureRandom.hex(29)}",
      submitted_at:     Time.current
    )
    other_investment = Investment.create!(
      user:              @user,
      deposit:           other_deposit,
      investment_plan:   @plan,
      principal_amount:  @plan.investment_amount_usd,
      daily_return_rate: @plan.daily_return_rate,
      duration_days:     @plan.duration_days,
      started_at:        Time.current,
      ends_at:           14.days.from_now
    )

    ProfitRecord.create!(valid_attributes)
    other_record = ProfitRecord.new(valid_attributes.merge(investment: other_investment))
    assert other_record.valid?
  end

  test "database enforces unique investment and profit_date at the database level" do
    ProfitRecord.create!(valid_attributes)
    assert_raises(ActiveRecord::RecordInvalid) do
      ProfitRecord.create!(valid_attributes)
    end
  end

  # Relationship tests
  test "belongs to a user" do
    record = ProfitRecord.create!(valid_attributes)
    assert_equal @user, record.user
  end

  test "belongs to an investment" do
    record = ProfitRecord.create!(valid_attributes)
    assert_equal @investment, record.investment
  end

  test "user has many profit records" do
    ProfitRecord.create!(valid_attributes)
    assert_includes @user.profit_records, ProfitRecord.last
  end

  test "investment has many profit records" do
    ProfitRecord.create!(valid_attributes)
    assert_includes @investment.profit_records, ProfitRecord.last
  end

  # Restrict on delete
  test "cannot destroy user with existing profit records" do
    ProfitRecord.create!(valid_attributes)
    assert_raises(ActiveRecord::DeleteRestrictionError) do
      @user.destroy
    end
  end

  test "cannot destroy investment with existing profit records" do
    ProfitRecord.create!(valid_attributes)
    assert_raises(ActiveRecord::DeleteRestrictionError) do
      @investment.destroy
    end
  end
end