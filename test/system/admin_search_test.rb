require "application_system_test_case"

class AdminSearchTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      full_name:             "Search Admin",
      email:                 "search_admin@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @admin.confirm
    @admin.update!(role: :admin)

    @alice = User.create!(
      full_name:             "Alice Searchable",
      email:                 "alice_search@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @alice.confirm

    @bob = User.create!(
      full_name:             "Bob Findable",
      email:                 "bob_search@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @bob.confirm

    create_all_six_plans
    @plan = InvestmentPlan.find_by(name: "Starter")

    @alice_deposit = Deposit.create!(
      user: @alice, investment_plan: @plan,
      amount_usd: @plan.investment_amount_usd, btc_amount: 0.001,
      transaction_hash: "alicesearch#{SecureRandom.hex(22)}",
      submitted_at: Time.current
    )

    @bob_deposit = Deposit.create!(
      user: @bob, investment_plan: @plan,
      amount_usd: @plan.investment_amount_usd, btc_amount: 0.001,
      transaction_hash: "bobsearch#{SecureRandom.hex(24)}",
      submitted_at: Time.current
    )

    @alice.wallet.update!(available_balance: 0.10)
    @bob.wallet.update!(available_balance: 0.10)

    @alice_withdrawal = Withdrawal.create!(
      user: @alice, amount: 0.01,
      btc_address: "bc1qalicesearch",
      status: :pending, requested_at: Time.current
    )
    @bob_withdrawal = Withdrawal.create!(
      user: @bob, amount: 0.01,
      btc_address: "bc1qbobsearch",
      status: :pending, requested_at: Time.current
    )
  end

  # --- Deposit search ---

  test "admin can search deposits by user name" do
    login_as @admin
    visit admin_deposits_path(status: "pending")
    fill_in "search", with: "Alice Searchable"
    click_button "Search"
    assert_text "Alice Searchable"
    assert_no_text "Bob Findable"
  end

  test "admin can clear deposit search" do
    login_as @admin
    visit admin_deposits_path(status: "pending", search: "Alice Searchable")
    assert_text "Alice Searchable"
    click_link "Clear"
    assert_text "Alice Searchable"
    assert_text "Bob Findable"
  end

  test "deposit search with no results shows empty state" do
    login_as @admin
    visit admin_deposits_path(status: "pending")
    fill_in "search", with: "zzznomatch999"
    click_button "Search"
    assert_text "No deposits found matching"
  end

  # --- Withdrawal search ---

  test "admin can search withdrawals by user name" do
    login_as @admin
    visit admin_withdrawals_path(status: "pending")
    fill_in "search", with: "Alice Searchable"
    click_button "Search"
    assert_text "Alice Searchable"
    assert_no_text "Bob Findable"
  end

  test "admin can search withdrawals by BTC address" do
    login_as @admin
    visit admin_withdrawals_path(status: "pending")
    fill_in "search", with: "bc1qalice"
    click_button "Search"
    assert_text "Alice Searchable"
    assert_no_text "Bob Findable"
  end

  test "withdrawal search with no results shows empty state" do
    login_as @admin
    visit admin_withdrawals_path(status: "pending")
    fill_in "search", with: "zzznomatch999"
    click_button "Search"
    assert_text "No withdrawals found matching"
  end

  # --- Investments admin page ---

  test "admin can visit admin investments index" do
    @alice_deposit.approve!(reviewer: @admin)
    login_as @admin
    visit admin_investments_path
    assert_text "Investments"
    assert_text "Alice Searchable"
  end

  test "admin investments search filters by investor" do
    @alice_deposit.approve!(reviewer: @admin)
    @bob_deposit.approve!(reviewer: @admin)
    login_as @admin
    visit admin_investments_path
    fill_in "search", with: "Alice Searchable"
    click_button "Search"
    assert_text "Alice Searchable"
    assert_no_text "Bob Findable"
  end

  test "Admin Investments nav link is visible to admins" do
    login_as @admin
    visit authenticated_root_path
    assert_selector "a[href='#{admin_investments_path}']"
  end
end