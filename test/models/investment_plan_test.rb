require "test_helper"

class InvestmentPlanTest < ActiveSupport::TestCase
  def valid_attributes
    {
      name: "Test Plan",
      description: "A test plan description.",
      investment_amount_usd: 1_000.00,
      daily_return_rate: 1.00,
      duration_days: 14,
      active: true,
      position: 99
    }
  end

  test "creates a valid investment plan with all required attributes" do
    plan = InvestmentPlan.new(valid_attributes)
    assert plan.valid?, "Expected plan to be valid but got: #{plan.errors.full_messages}"
  end

  test "is invalid without a name" do
    plan = InvestmentPlan.new(valid_attributes.merge(name: ""))
    assert_not plan.valid?
    assert_includes plan.errors[:name], "can't be blank"
  end

  test "is invalid with a duplicate name" do
    InvestmentPlan.create!(valid_attributes)
    duplicate = InvestmentPlan.new(valid_attributes.merge(position: 98))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "is invalid when investment_amount_usd is zero" do
    plan = InvestmentPlan.new(valid_attributes.merge(investment_amount_usd: 0))
    assert_not plan.valid?
    assert plan.errors[:investment_amount_usd].any?
  end

  test "is invalid when investment_amount_usd is negative" do
    plan = InvestmentPlan.new(valid_attributes.merge(investment_amount_usd: -100))
    assert_not plan.valid?
    assert plan.errors[:investment_amount_usd].any?
  end

  test "is invalid without investment_amount_usd" do
    plan = InvestmentPlan.new(valid_attributes.merge(investment_amount_usd: nil))
    assert_not plan.valid?
    assert plan.errors[:investment_amount_usd].any?
  end

  test "is invalid when daily_return_rate is zero" do
    plan = InvestmentPlan.new(valid_attributes.merge(daily_return_rate: 0))
    assert_not plan.valid?
    assert plan.errors[:daily_return_rate].any?
  end

  test "is invalid when daily_return_rate is negative" do
    plan = InvestmentPlan.new(valid_attributes.merge(daily_return_rate: -1))
    assert_not plan.valid?
    assert plan.errors[:daily_return_rate].any?
  end

  test "is invalid without daily_return_rate" do
    plan = InvestmentPlan.new(valid_attributes.merge(daily_return_rate: nil))
    assert_not plan.valid?
    assert plan.errors[:daily_return_rate].any?
  end

  test "is invalid when duration_days is zero" do
    plan = InvestmentPlan.new(valid_attributes.merge(duration_days: 0))
    assert_not plan.valid?
    assert plan.errors[:duration_days].any?
  end

  test "is invalid when duration_days is negative" do
    plan = InvestmentPlan.new(valid_attributes.merge(duration_days: -7))
    assert_not plan.valid?
    assert plan.errors[:duration_days].any?
  end

  test "is invalid when duration_days is not an integer" do
    plan = InvestmentPlan.new(valid_attributes.merge(duration_days: 14.5))
    assert_not plan.valid?
    assert plan.errors[:duration_days].any?
  end

  test "is invalid with a duplicate position" do
    InvestmentPlan.create!(valid_attributes)
    duplicate = InvestmentPlan.new(valid_attributes.merge(name: "Other Plan"))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:position], "has already been taken"
  end

  test "is invalid when position is zero" do
    plan = InvestmentPlan.new(valid_attributes.merge(position: 0))
    assert_not plan.valid?
    assert plan.errors[:position].any?
  end

  test "active scope returns only active plans" do
    active_plan   = create_investment_plan(active: true)
    inactive_plan = create_investment_plan(active: false)
    assert_includes     InvestmentPlan.active, active_plan
    assert_not_includes InvestmentPlan.active, inactive_plan
  end

  test "ordered scope returns plans sorted by position ascending" do
    create_investment_plan(position: 201)
    create_investment_plan(position: 200)
    create_investment_plan(position: 202)
    positions = InvestmentPlan.ordered.map(&:position)
    assert_equal positions.sort, positions
  end

  test "visible scope excludes inactive plans" do
    inactive = create_investment_plan(active: false)
    assert_not_includes InvestmentPlan.visible, inactive
  end

  test "visible scope returns plans in position order" do
    create_investment_plan(position: 211)
    create_investment_plan(position: 210)
    positions = InvestmentPlan.visible.map(&:position)
    assert_equal positions.sort, positions
  end

  # Seed structure correctness — verified by creating the same structure in test
  test "all six canonical plans can be created with correct attributes" do
    plans = create_all_six_plans
    assert_equal 6, plans.size
    assert_equal %w[Starter Bronze Silver Gold Platinum VIP], plans.map(&:name)
    assert_equal [1, 2, 3, 4, 5, 6], plans.map(&:position)
    assert plans.all?(&:active?)
  end
end