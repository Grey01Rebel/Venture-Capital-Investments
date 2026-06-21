require "application_system_test_case"

class ProfitsTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      full_name:             "Profits Admin",
      email:                 "profits_admin@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @admin.confirm
    @admin.update!(role: :admin)

    @member = User.create!(
      full_name:             "Profits Member",
      email:                 "profits_member@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @member.confirm

    @other = User.create!(
      full_name:             "Other Member",
      email:                 "other_member@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @other.confirm

    create_all_six_plans
    @plan = InvestmentPlan.find_by(name: "Starter")
  end

  def build_investment(user, hash_prefix)
    deposit = Deposit.create!(
      user:             user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "#{hash_prefix}#{SecureRandom.hex(24)}",
      submitted_at:     Time.current
    )
    deposit.approve!(reviewer: @admin)
    deposit.reload
    deposit.investment
  end

  test "user sees their own profit records" do
    investment = build_investment(@member, "systest1")
    ProfitRecord.create!(
      user:        @member,
      investment:  investment,
      amount:      4.00,
      profit_date: Date.current
    )

    login_as @member
    visit profits_path

    assert_text "My Profit Records"
    assert_text "Starter"
    assert_text "$4.00"
    assert_text "Active"
  end

  test "user does not see other users' profit records" do
    member_investment = build_investment(@member, "systest2")
    other_investment  = build_investment(@other,   "systest3")

    ProfitRecord.create!(
      user:        @member,
      investment:  member_investment,
      amount:      4.00,
      profit_date: Date.current
    )
    ProfitRecord.create!(
      user:        @other,
      investment:  other_investment,
      amount:      9.99,
      profit_date: Date.current
    )

    login_as @member
    visit profits_path

    assert_text "$4.00"
    assert_no_text "$9.99"
  end

  test "empty state renders correctly when user has no profit records" do
    login_as @member
    visit profits_path
    assert_text "No profit records yet."
    assert_text "Browse Investment Plans"
  end

  test "My Profits navigation link is visible and works" do
    login_as @member
    visit authenticated_root_path
    assert_selector "a[href='#{profits_path}']"
    click_link "My Profits"
    assert_current_path profits_path
    assert_text "My Profit Records"
  end

  test "unauthenticated user is redirected from profits page" do
    visit profits_path
    assert_current_path new_user_session_path
  end

  test "admin sees profit records from all users" do
    member_investment = build_investment(@member, "systest4")
    other_investment  = build_investment(@other,   "systest5")

    ProfitRecord.create!(
      user:        @member,
      investment:  member_investment,
      amount:      4.00,
      profit_date: Date.current
    )
    ProfitRecord.create!(
      user:        @other,
      investment:  other_investment,
      amount:      6.50,
      profit_date: Date.current
    )

    login_as @admin
    visit profits_path

    assert_text "$4.00"
    assert_text "$6.50"
  end
end