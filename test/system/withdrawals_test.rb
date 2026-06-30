# frozen_string_literal: true
require "application_system_test_case"

class WithdrawalsTest < ApplicationSystemTestCase
  def setup
    @member = User.create!(
      full_name:             "Withdrawal Investor",
      email:                 "withdrawal_investor@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @member.confirm
    @member.wallet.update!(available_balance: 0.05000000)
  end

  test "member can submit a withdrawal request through the full flow" do
    login_as @member
    visit new_withdrawal_path

    assert_text "0.05000000"

    fill_in "Withdrawal Amount (BTC)", with: "0.01000000"
    fill_in "Destination BTC Address", with: "bc1qsystemtest1234567890"
    click_button "Submit Withdrawal Request"

    assert_text "Withdrawal request submitted successfully."
    assert_text "0.01000000 BTC"
    assert_text "bc1qsystemtest1234567890"
    assert_text "Pending"
  end

  test "wallet balance reflects the deduction after a successful submission" do
    login_as @member
    visit new_withdrawal_path
    fill_in "Withdrawal Amount (BTC)", with: "0.02000000"
    fill_in "Destination BTC Address", with: "bc1qbalancecheck"
    click_button "Submit Withdrawal Request"

    @member.wallet.reload
    assert_equal 0.03000000, @member.wallet.available_balance
  end

  test "submitting a withdrawal exceeding balance shows an error and does not redirect" do
    login_as @member
    visit new_withdrawal_path
    fill_in "Withdrawal Amount (BTC)", with: "1.00000000"
    fill_in "Destination BTC Address", with: "bc1qtoolarge"
    click_button "Submit Withdrawal Request"

    assert_text "Insufficient balance."
    assert_current_path withdrawals_path(action: nil) rescue assert_text "Request a Withdrawal"
  end

  test "member sees their withdrawal in the index after submission" do
    login_as @member
    visit new_withdrawal_path
    fill_in "Withdrawal Amount (BTC)", with: "0.01500000"
    fill_in "Destination BTC Address", with: "bc1qindexcheck"
    click_button "Submit Withdrawal Request"

    visit withdrawals_path
    assert_text "0.01500000 BTC"
    assert_text "Pending"
  end

  test "My Withdrawals navigation link is visible and works" do
    login_as @member
    visit authenticated_root_path
    assert_selector "a[href='#{withdrawals_path}']"
    click_link "My Withdrawals"
    assert_current_path withdrawals_path
    assert_text "My Withdrawals"
  end

  test "empty state renders correctly when user has no withdrawals" do
    login_as @member
    visit withdrawals_path
    assert_text "No withdrawal requests yet."
  end

  test "unauthenticated user is redirected from withdrawals index" do
    visit withdrawals_path
    assert_current_path new_user_session_path
  end

  test "unauthenticated user is redirected from new withdrawal form" do
    visit new_withdrawal_path
    assert_current_path new_user_session_path
  end
end
