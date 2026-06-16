# frozen_string_literal: true
require "test_helper"

class InvestmentPolicyTest < ActiveSupport::TestCase
  def setup
    @member      = create_confirmed_user
    @other       = create_confirmed_user
    @admin       = create_confirmed_user
    @admin.update!(role: :admin)

    @plan = create_investment_plan(position: 1001)

    @member_deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "invpol#{SecureRandom.hex(27)}",
      submitted_at:     Time.current
    )

    @other_deposit = Deposit.create!(
      user:             @other,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "invpol2#{SecureRandom.hex(26)}",
      submitted_at:     Time.current
    )

    @member_investment = Investment.create!(
      user:              @member,
      deposit:           @member_deposit,
      investment_plan:   @plan,
      principal_amount:  @plan.investment_amount_usd,
      daily_return_rate: @plan.daily_return_rate,
      duration_days:     @plan.duration_days,
      started_at:        Time.current,
      ends_at:           14.days.from_now
    )

    @other_investment = Investment.create!(
      user:              @other,
      deposit:           @other_deposit,
      investment_plan:   @plan,
      principal_amount:  @plan.investment_amount_usd,
      daily_return_rate: @plan.daily_return_rate,
      duration_days:     @plan.duration_days,
      started_at:        Time.current,
      ends_at:           14.days.from_now
    )
  end

  # index?
  test "member can access investment index" do
    assert InvestmentPolicy.new(@member, Investment).index?
  end

  test "admin can access investment index" do
    assert InvestmentPolicy.new(@admin, Investment).index?
  end

  # show? — member
  test "member can view their own investment" do
    assert InvestmentPolicy.new(@member, @member_investment).show?
  end

  test "member cannot view another member's investment" do
    assert_not InvestmentPolicy.new(@member, @other_investment).show?
  end

  # show? — admin
  test "admin can view any investment" do
    assert InvestmentPolicy.new(@admin, @member_investment).show?
    assert InvestmentPolicy.new(@admin, @other_investment).show?
  end

  # Scope — member
  test "policy scope for member returns only their investments" do
    scope   = InvestmentPolicy::Scope.new(@member, Investment.all)
    results = scope.resolve
    assert_includes     results, @member_investment
    assert_not_includes results, @other_investment
  end

  # Scope — admin
  test "policy scope for admin returns all investments" do
    scope   = InvestmentPolicy::Scope.new(@admin, Investment.all)
    results = scope.resolve
    assert_includes results, @member_investment
    assert_includes results, @other_investment
  end

  # Unauthenticated
  test "unauthenticated access raises NotAuthorizedError" do
    assert_raises(Pundit::NotAuthorizedError) do
      InvestmentPolicy.new(nil, Investment)
    end
  end

  test "policy scope raises NotAuthorizedError for unauthenticated user" do
    assert_raises(Pundit::NotAuthorizedError) do
      InvestmentPolicy::Scope.new(nil, Investment.all)
    end
  end
end
