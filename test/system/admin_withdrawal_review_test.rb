# frozen_string_literal: true
require "application_system_test_case"

class AdminWithdrawalReviewTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      full_name:             "Review Admin",
      email:                 "review_admin@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @admin.confirm
    @admin.update!(role: :admin)

    @member = User.create!(
      full_name:             "Review Member",
      email:                 "review_member@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @member.confirm
    @member.wallet.update!(available_balance: 0.04000000)

    @withdrawal = Withdrawal.create!(
      user:         @member,
      amount:       0.01000000,
      btc_address:  "bc1qsystemreview",
      status:       :pending,
      requested_at: Time.current
    )
  end

  test "admin can navigate to admin withdrawals" do
    login_as @admin
    visit authenticated_root_path
    assert_selector "a[href='#{admin_withdrawals_path}']"
    click_link "Admin Withdrawals"
    assert_current_path admin_withdrawals_path
    assert_text "Withdrawal Requests"
  end

  test "admin sees pending withdrawal in index" do
    login_as @admin
    visit admin_withdrawals_path
    assert_text "0.01000000 BTC"
    assert_text "Review Member"
  end

  test "admin can approve a pending withdrawal" do
    login_as @admin
    visit admin_withdrawal_path(@withdrawal)
    click_button "Approve Withdrawal"
    assert_text "Withdrawal approved."
    assert_text "Approved"
  end

  test "admin can reject a pending withdrawal" do
    login_as @admin
    visit admin_withdrawal_path(@withdrawal)
    click_button "Reject Withdrawal"
    assert_text "Withdrawal rejected and funds returned."
    assert_text "Rejected"
  end

  test "rejection restores member wallet balance" do
    login_as @admin
    visit admin_withdrawal_path(@withdrawal)
    click_button "Reject Withdrawal"

    @member.wallet.reload
    assert_equal 0.05000000, @member.wallet.available_balance
  end

  test "approval does not change wallet balance" do
    login_as @admin
    visit admin_withdrawal_path(@withdrawal)
    click_button "Approve Withdrawal"

    @member.wallet.reload
    assert_equal 0.04000000, @member.wallet.available_balance
  end

  test "reviewed withdrawal shows read-only review section, not action forms" do
    @withdrawal.update!(
      status:           :completed,
      approved_at:      Time.current,
      completed_at:     Time.current,
      transaction_hash: "completed_review_hash",
      reviewed_by_id:   @admin.id
    )

    login_as @admin
    visit admin_withdrawal_path(@withdrawal)

    assert_no_text "Approve Withdrawal"
    assert_no_text "Reject Withdrawal"
    assert_no_text "Complete Withdrawal"
    assert_text "Reviewed By"
  end
  test "member cannot access admin withdrawal review" do
    login_as @member
    visit admin_withdrawals_path
    assert_no_current_path admin_withdrawals_path
  end
end
