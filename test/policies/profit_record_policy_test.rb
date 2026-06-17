# frozen_string_literal: true
require "test_helper"

class ProfitRecordPolicyTest < ActiveSupport::TestCase
  def setup
    @member = create_confirmed_user
    @other  = create_confirmed_user
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)

    @plan = create_investment_plan(position: 1401)

    @member_investment = build_investment(@member, "prpol#{SecureRandom.hex(27)}")
    @other_investment  = build_investment(@other,  "prpol2#{SecureRandom.hex(26)}")

    @member_record = ProfitRecord.create!(
      user:        @member,
      investment:  @member_investment,
      amount:      4.00,
      profit_date: Date.current
    )

    @other_record = ProfitRecord.create!(
      user:        @other,
      investment:  @other_investment,
      amount:      4.00,
      profit_date: Date.current
    )
  end

  def build_investment(user, hash)
    deposit = Deposit.create!(
      user:             user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: hash,
      submitted_at:     Time.current
    )
    Investment.create!(
      user:              user,
      deposit:           deposit,
      investment_plan:   @plan,
      principal_amount:  @plan.investment_amount_usd,
      daily_return_rate: @plan.daily_return_rate,
      duration_days:     @plan.duration_days,
      started_at:        Time.current,
      ends_at:           14.days.from_now
    )
  end

  # index?
  test "member can access profit record index" do
    assert ProfitRecordPolicy.new(@member, ProfitRecord).index?
  end

  test "admin can access profit record index" do
    assert ProfitRecordPolicy.new(@admin, ProfitRecord).index?
  end

  # show? — member
  test "member can view their own profit record" do
    assert ProfitRecordPolicy.new(@member, @member_record).show?
  end

  test "member cannot view another member's profit record" do
    assert_not ProfitRecordPolicy.new(@member, @other_record).show?
  end

  # show? — admin
  test "admin can view any profit record" do
    assert ProfitRecordPolicy.new(@admin, @member_record).show?
    assert ProfitRecordPolicy.new(@admin, @other_record).show?
  end

  # Scope — member
  test "policy scope for member returns only their own profit records" do
    scope   = ProfitRecordPolicy::Scope.new(@member, ProfitRecord.all)
    results = scope.resolve
    assert_includes     results, @member_record
    assert_not_includes results, @other_record
  end

  # Scope — admin
  test "policy scope for admin returns all profit records" do
    scope   = ProfitRecordPolicy::Scope.new(@admin, ProfitRecord.all)
    results = scope.resolve
    assert_includes results, @member_record
    assert_includes results, @other_record
  end

  # Unauthenticated
  test "unauthenticated access raises NotAuthorizedError" do
    assert_raises(Pundit::NotAuthorizedError) do
      ProfitRecordPolicy.new(nil, ProfitRecord)
    end
  end

  test "policy scope raises NotAuthorizedError for unauthenticated user" do
    assert_raises(Pundit::NotAuthorizedError) do
      ProfitRecordPolicy::Scope.new(nil, ProfitRecord.all)
    end
  end
end
