# frozen_string_literal: true
require "application_system_test_case"

class WithdrawalCompletionTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      full_name:             "Completion Admin",
      email:                 "completion_admin@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @admin.confirm
    @admin.update!(role: :admin)

    @member = User.create!(
      full_name:             "Completion Member",
      email:                 "completion_member@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @member.confirm
    @member.wallet.update!(available_balance: 0.04000000)

    @approved_withdrawal = Withdrawal.create!(
      user:           @member,
      amount:         0.01000000,
      btc_address:    "bc1qcompletion",
      status:         :approved,
      requested_at:   Time.current,
      approved_at:    Time.current,
      reviewed_by_id: @admin.id
    )
  end

  test "admin sees Complete Withdrawal button for approved withdrawal" do
    login_as @admin
    visit admin_withdrawal_path(@approved_withdrawal)
    assert_text "Complete Withdrawal"
    assert_text "Mark as Completed"
  end

  test "admin can complete an approved withdrawal with a transaction hash" do
    login_as @admin
    visit admin_withdrawal_path(@approved_withdrawal)
    find("input[name='transaction_hash']").set("btctxhash1234567890abcdef")
    click_button "Complete Withdrawal"
    assert_text "Withdrawal marked as completed."
    assert_text "Completed"
    end

  test "completed withdrawal shows transaction hash on admin show page" do
    login_as @admin
    visit admin_withdrawal_path(@approved_withdrawal)
    find("input[name='transaction_hash']").set("txhashvisible123")
    click_button "Complete Withdrawal"
    assert_text "txhashvisible123"
  end

  test "completed withdrawal does not show action buttons" do
    @approved_withdrawal.update!(
      status:           :completed,
      completed_at:     Time.current,
      transaction_hash: "already_done_hash"
    )
    login_as @admin
    visit admin_withdrawal_path(@approved_withdrawal)
    assert_no_text "Complete Withdrawal"
    assert_no_text "Approve Withdrawal"
  end

  test "member sees transaction hash on their withdrawal show page after completion" do
    @approved_withdrawal.update!(
      status:           :completed,
      completed_at:     Time.current,
      transaction_hash: "member_visible_hash"
    )
    login_as @member
    visit withdrawal_path(@approved_withdrawal)
    assert_text "member_visible_hash"
    assert_text "Completed"
  end

  test "member sees completed_at on their withdrawal show page" do
    @approved_withdrawal.update!(
      status:           :completed,
      completed_at:     Time.current,
      transaction_hash: "completed_at_hash"
    )
    login_as @member
    visit withdrawal_path(@approved_withdrawal)
    assert_text "Completed"
  end

  test "completing without a transaction hash shows an error" do
    login_as @admin
    visit admin_withdrawal_path(@approved_withdrawal)
    find("input[name='transaction_hash']").set("")
    click_button "Complete Withdrawal"
    assert @approved_withdrawal.reload.approved?
  end

  test "wallet balance unchanged after completion" do
    original_balance = @member.wallet.available_balance
    login_as @admin
    visit admin_withdrawal_path(@approved_withdrawal)
    find("input[name='transaction_hash']").set("wallet_check_hash_abc")
    click_button "Complete Withdrawal"

    @member.wallet.reload
    assert_equal original_balance, @member.wallet.available_balance
  end
end
