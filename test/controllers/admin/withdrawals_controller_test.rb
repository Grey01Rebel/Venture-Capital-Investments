require "test_helper"

class Admin::WithdrawalsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin  = create_confirmed_user
    @admin.update!(role: :admin)
    @member = create_confirmed_user
    @member.wallet.update!(available_balance: 0.10000000)

    @withdrawal = Withdrawal.create!(
      user:         @member,
      amount:       0.01000000,
      btc_address:  "bc1qadmintest",
      status:       :pending,
      requested_at: Time.current
    )

    @approved_withdrawal = Withdrawal.create!(
      user:           @member,
      amount:         0.01000000,
      btc_address:    "bc1qapproved",
      status:         :approved,
      requested_at:   Time.current,
      approved_at:    Time.current,
      reviewed_by_id: @admin.id
    )
  end

  # --- index ---

  test "admin can access withdrawals index" do
    sign_in @admin
    get admin_withdrawals_path
    assert_response :success
  end

  test "non-admin is redirected from admin withdrawals index" do
    sign_in @member
    get admin_withdrawals_path
    assert_redirected_to authenticated_root_path
  end

  test "unauthenticated user is redirected from admin withdrawals index" do
    get admin_withdrawals_path
    assert_redirected_to new_user_session_path
  end

  test "index defaults to pending tab" do
    sign_in @admin
    get admin_withdrawals_path
    assert_match "Pending", response.body
  end

  test "index shows approved withdrawals when filtered" do
    sign_in @admin
    get admin_withdrawals_path(status: "approved")
    assert_match "0.01000000 BTC", response.body
  end

  test "index shows completed tab" do
    sign_in @admin
    get admin_withdrawals_path(status: "completed")
    assert_response :success
  end

  # --- show ---

  test "admin can view a withdrawal" do
    sign_in @admin
    get admin_withdrawal_path(@withdrawal)
    assert_response :success
  end

  test "show displays withdrawal amount" do
    sign_in @admin
    get admin_withdrawal_path(@withdrawal)
    assert_match "0.01000000 BTC", response.body
  end

  test "show displays BTC address" do
    sign_in @admin
    get admin_withdrawal_path(@withdrawal)
    assert_match "bc1qadmintest", response.body
  end

  test "show displays approve button for pending withdrawal" do
    sign_in @admin
    get admin_withdrawal_path(@withdrawal)
    assert_match "Approve Withdrawal", response.body
  end

  test "show displays complete button for approved withdrawal" do
    sign_in @admin
    get admin_withdrawal_path(@approved_withdrawal)
    assert_match "Complete Withdrawal", response.body
  end

  test "non-admin cannot view admin withdrawal show" do
    sign_in @member
    get admin_withdrawal_path(@withdrawal)
    assert_redirected_to authenticated_root_path
  end

  # --- approve ---

  test "admin can approve a pending withdrawal" do
    sign_in @admin
    patch approve_admin_withdrawal_path(@withdrawal), params: { admin_notes: "" }
    assert @withdrawal.reload.approved?
  end

  test "approval redirects to withdrawal show" do
    sign_in @admin
    patch approve_admin_withdrawal_path(@withdrawal), params: { admin_notes: "" }
    assert_redirected_to admin_withdrawal_path(@withdrawal)
  end

  test "approval does not change wallet balance" do
    original_balance = @member.wallet.available_balance
    sign_in @admin
    patch approve_admin_withdrawal_path(@withdrawal), params: { admin_notes: "" }
    @member.wallet.reload
    assert_equal original_balance, @member.wallet.available_balance
  end

  test "non-admin cannot approve a withdrawal" do
    sign_in @member
    patch approve_admin_withdrawal_path(@withdrawal), params: { admin_notes: "" }
    assert_redirected_to authenticated_root_path
    assert @withdrawal.reload.pending?
  end

  # --- reject ---

  test "admin can reject a pending withdrawal" do
    sign_in @admin
    patch reject_admin_withdrawal_path(@withdrawal), params: { admin_notes: "" }
    assert @withdrawal.reload.rejected?
  end

  test "rejection redirects to withdrawal show" do
    sign_in @admin
    patch reject_admin_withdrawal_path(@withdrawal), params: { admin_notes: "" }
    assert_redirected_to admin_withdrawal_path(@withdrawal)
  end

  test "rejection restores wallet available_balance" do
    original_balance = @member.wallet.available_balance
    sign_in @admin
    patch reject_admin_withdrawal_path(@withdrawal), params: { admin_notes: "" }
    @member.wallet.reload
    assert_equal original_balance + @withdrawal.amount, @member.wallet.available_balance
  end

  test "non-admin cannot reject a withdrawal" do
    sign_in @member
    patch reject_admin_withdrawal_path(@withdrawal), params: { admin_notes: "" }
    assert_redirected_to authenticated_root_path
    assert @withdrawal.reload.pending?
  end

  test "cannot approve an already-approved withdrawal" do
    sign_in @admin
    patch approve_admin_withdrawal_path(@approved_withdrawal), params: { admin_notes: "" }
    follow_redirect!
    assert_match "not pending", response.body
  end

  # --- complete ---

  test "admin can complete an approved withdrawal" do
    sign_in @admin
    patch complete_admin_withdrawal_path(@approved_withdrawal),
          params: { transaction_hash: "valid_tx_hash_abc123" }
    assert @approved_withdrawal.reload.completed?
  end

  test "complete redirects to withdrawal show" do
    sign_in @admin
    patch complete_admin_withdrawal_path(@approved_withdrawal),
          params: { transaction_hash: "valid_tx_hash_redirect" }
    assert_redirected_to admin_withdrawal_path(@approved_withdrawal)
  end

  test "complete stores the transaction hash" do
    sign_in @admin
    patch complete_admin_withdrawal_path(@approved_withdrawal),
          params: { transaction_hash: "stored_tx_hash_xyz" }
    assert_equal "stored_tx_hash_xyz", @approved_withdrawal.reload.transaction_hash
  end

  test "complete does not modify wallet balance" do
    original_balance = @member.wallet.available_balance
    sign_in @admin
    patch complete_admin_withdrawal_path(@approved_withdrawal),
          params: { transaction_hash: "wallet_check_tx_hash" }
    @member.wallet.reload
    assert_equal original_balance, @member.wallet.available_balance
  end

  test "complete fails without a transaction hash" do
    sign_in @admin
    patch complete_admin_withdrawal_path(@approved_withdrawal),
          params: { transaction_hash: "" }
    follow_redirect!
    assert_match "Transaction hash is required.", response.body
    assert @approved_withdrawal.reload.approved?
  end

  test "non-admin cannot complete a withdrawal" do
    sign_in @member
    patch complete_admin_withdrawal_path(@approved_withdrawal),
          params: { transaction_hash: "unauthorised_hash" }
    assert_redirected_to authenticated_root_path
    assert @approved_withdrawal.reload.approved?
  end

  test "cannot complete a pending withdrawal" do
    sign_in @admin
    patch complete_admin_withdrawal_path(@withdrawal),
          params: { transaction_hash: "pending_hash_xyz" }
    follow_redirect!
    assert_match "not approved", response.body
    assert @withdrawal.reload.pending?
  end
end