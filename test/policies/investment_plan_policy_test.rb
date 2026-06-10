require "test_helper"

class InvestmentPlanPolicyTest < ActiveSupport::TestCase
  def setup
    @user          = create_confirmed_user
    @active_plan   = create_investment_plan(active: true,  position: 301)
    @inactive_plan = create_investment_plan(active: false, position: 302)
  end

  test "authenticated user can access plans index" do
    policy = InvestmentPlanPolicy.new(@user, InvestmentPlan)
    assert policy.index?
  end

  test "authenticated user can view an active plan" do
    policy = InvestmentPlanPolicy.new(@user, @active_plan)
    assert policy.show?
  end

  test "unauthenticated access raises NotAuthorizedError" do
    assert_raises(Pundit::NotAuthorizedError) do
      InvestmentPlanPolicy.new(nil, InvestmentPlan)
    end
  end

  test "policy scope returns only active plans" do
    scope   = InvestmentPlanPolicy::Scope.new(@user, InvestmentPlan.all)
    results = scope.resolve
    assert_includes     results, @active_plan
    assert_not_includes results, @inactive_plan
  end

  test "policy scope returns plans ordered by position" do
    create_investment_plan(position: 312)
    create_investment_plan(position: 310)
    create_investment_plan(position: 311)
    scope     = InvestmentPlanPolicy::Scope.new(@user, InvestmentPlan.all)
    positions = scope.resolve.map(&:position)
    assert_equal positions.sort, positions
  end

  test "policy scope raises NotAuthorizedError for unauthenticated user" do
    assert_raises(Pundit::NotAuthorizedError) do
      InvestmentPlanPolicy::Scope.new(nil, InvestmentPlan.all)
    end
  end
end