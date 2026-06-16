# frozen_string_literal: true
require "test_helper"

class InvestmentCreationServiceTest < ActiveSupport::TestCase
  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @member = create_confirmed_user
    @plan   = create_investment_plan(position: 1101)

    @deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "svc#{SecureRandom.hex(30)}",
      submitted_at:     Time.current
    )
  end

  def approve_deposit
    @deposit.approve!(reviewer: @admin)
    @deposit.reload
  end

  # Guard — non-approved deposit
  test "returns failure for a pending deposit" do
    result = InvestmentCreationService.new(@deposit).call
    assert_not result.success?
    assert_equal "Deposit is not approved.", result.error
    assert_nil result.investment
  end

  test "returns failure for a rejected deposit" do
    @deposit.reject!(reviewer: @admin)
    result = InvestmentCreationService.new(@deposit.reload).call
    assert_not result.success?
    assert_equal "Deposit is not approved.", result.error
  end

  # Guard — already has investment
  test "returns failure if deposit already has an investment" do
    approve_deposit
    result = InvestmentCreationService.new(@deposit).call
    assert_not result.success?
    assert_equal "An investment already exists for this deposit.", result.error
  end

  # Successful creation via approve!
  test "approve! creates an investment" do
    assert_difference "Investment.count", 1 do
      approve_deposit
    end
  end

  test "investment is associated with the correct user" do
    approve_deposit
    assert_equal @member, @deposit.investment.user
  end

  test "investment is associated with the correct deposit" do
    approve_deposit
    assert_equal @deposit, @deposit.investment.deposit
  end

  test "investment is associated with the correct plan" do
    approve_deposit
    assert_equal @plan, @deposit.investment.investment_plan
  end

  test "principal_amount is copied from deposit amount_usd" do
    approve_deposit
    assert_equal @deposit.amount_usd, @deposit.investment.principal_amount
  end

  test "daily_return_rate is copied from the plan" do
    approve_deposit
    assert_equal @plan.daily_return_rate, @deposit.investment.daily_return_rate
  end

  test "duration_days is copied from the plan" do
    approve_deposit
    assert_equal @plan.duration_days, @deposit.investment.duration_days
  end

  test "started_at is set to deposit approved_at" do
    approve_deposit
    assert_equal @deposit.approved_at, @deposit.investment.started_at
  end

  test "ends_at is started_at plus duration_days" do
    approve_deposit
    expected = @deposit.approved_at + @plan.duration_days.days
    assert_equal expected, @deposit.investment.ends_at
  end

  test "investment status defaults to active" do
    approve_deposit
    assert @deposit.investment.active?
  end

  # Atomicity — if investment creation fails, deposit approval rolls back
  test "deposit remains pending if investment creation fails" do
    # Create a duplicate investment to trigger uniqueness failure
    Investment.create!(
      user:              @member,
      deposit:           @deposit,
      investment_plan:   @plan,
      principal_amount:  500.00,
      daily_return_rate: 0.80,
      duration_days:     14,
      started_at:        Time.current,
      ends_at:           14.days.from_now
    )

    # Now approve — investment creation will fail due to uniqueness
    result = @deposit.approve!(reviewer: @admin)

    # approve! returns false when transaction rolls back
    assert_equal false, result
    assert @deposit.reload.pending?
  end
end
