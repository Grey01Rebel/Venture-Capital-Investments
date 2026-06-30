# frozen_string_literal: true
require "test_helper"

class WithdrawalsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @member = create_confirmed_user
    @other  = create_confirmed_user
    @member.wallet.update!(available_balance: 0.05000000)
    @other.wallet.update!(available_balance: 0.05000000)
  end

  # --- index ---

  test "authenticated user can access withdrawals index" do
    sign_in @member
    get withdrawals_path
    assert_response :success
  end

  test "unauthenticated user is redirected from withdrawals index" do
    get withdrawals_path
    assert_redirected_to new_user_session_path
  end

  test "member only sees their own withdrawals" do
    Withdrawal.create!(user: @member, amount: 0.01, btc_address: "bc1qmember", status: :pending, requested_at: Time.current)
    Withdrawal.create!(user: @other,  amount: 0.09, btc_address: "bc1qother",  status: :pending, requested_at: Time.current)

    sign_in @member
    get withdrawals_path

    assert_match "0.01000000 BTC", response.body
    assert_no_match "0.09000000 BTC", response.body
  end

  test "index shows empty state when user has no withdrawals" do
    sign_in @member
    get withdrawals_path
    assert_match "No withdrawal requests yet.", response.body
  end

  # --- new ---

  test "authenticated user can access new withdrawal form" do
    sign_in @member
    get new_withdrawal_path
    assert_response :success
  end

  test "new withdrawal form displays available balance" do
    sign_in @member
    get new_withdrawal_path
    assert_match "0.05000000", response.body
  end

  test "unauthenticated user is redirected from new withdrawal form" do
    get new_withdrawal_path
    assert_redirected_to new_user_session_path
  end

  # --- create ---

  test "authenticated user can submit a valid withdrawal request" do
    sign_in @member
    assert_difference "Withdrawal.count", 1 do
      post withdrawals_path, params: { withdrawal: { amount: "0.01000000", btc_address: "bc1qnewrequest" } }
    end
  end

  test "successful withdrawal creation redirects to the withdrawal show page" do
    sign_in @member
    post withdrawals_path, params: { withdrawal: { amount: "0.01000000", btc_address: "bc1qredirect" } }
    assert_redirected_to withdrawal_path(Withdrawal.last)
  end

  test "successful withdrawal reduces wallet available_balance" do
    sign_in @member
    post withdrawals_path, params: { withdrawal: { amount: "0.01000000", btc_address: "bc1qreduce" } }
    @member.wallet.reload
    assert_equal 0.04000000, @member.wallet.available_balance
  end

  test "withdrawal request with insufficient balance does not create a record" do
    sign_in @member
    assert_no_difference "Withdrawal.count" do
      post withdrawals_path, params: { withdrawal: { amount: "1.00000000", btc_address: "bc1qtoomuch" } }
    end
  end

  test "withdrawal request with insufficient balance re-renders the new form" do
    sign_in @member
    post withdrawals_path, params: { withdrawal: { amount: "1.00000000", btc_address: "bc1qtoomuch" } }
    assert_response :unprocessable_entity
    assert_match "Insufficient balance.", response.body
  end

  test "withdrawal request with zero amount fails gracefully" do
    sign_in @member
    post withdrawals_path, params: { withdrawal: { amount: "0", btc_address: "bc1qzero" } }
    assert_response :unprocessable_entity
  end

  test "unauthenticated user cannot submit a withdrawal request" do
    post withdrawals_path, params: { withdrawal: { amount: "0.01", btc_address: "bc1qunauth" } }
    assert_redirected_to new_user_session_path
  end

  # --- show ---

  test "member can view their own withdrawal" do
    withdrawal = Withdrawal.create!(user: @member, amount: 0.01, btc_address: "bc1qshow", status: :pending, requested_at: Time.current)
    sign_in @member
    get withdrawal_path(withdrawal)
    assert_response :success
  end

  test "member cannot view another member's withdrawal" do
    other_withdrawal = Withdrawal.create!(user: @other, amount: 0.01, btc_address: "bc1qother2", status: :pending, requested_at: Time.current)
    sign_in @member
    get withdrawal_path(other_withdrawal)
    assert_response :redirect
  end

  test "withdrawal show displays amount" do
    withdrawal = Withdrawal.create!(user: @member, amount: 0.01234567, btc_address: "bc1qamount", status: :pending, requested_at: Time.current)
    sign_in @member
    get withdrawal_path(withdrawal)
    assert_match "0.01234567", response.body
  end

  test "withdrawal show displays btc_address" do
    withdrawal = Withdrawal.create!(user: @member, amount: 0.01, btc_address: "bc1qdisplayaddress", status: :pending, requested_at: Time.current)
    sign_in @member
    get withdrawal_path(withdrawal)
    assert_match "bc1qdisplayaddress", response.body
  end

  test "withdrawal show displays status" do
    withdrawal = Withdrawal.create!(user: @member, amount: 0.01, btc_address: "bc1qstatus", status: :pending, requested_at: Time.current)
    sign_in @member
    get withdrawal_path(withdrawal)
    assert_match "Pending", response.body
  end

  test "unauthenticated user is redirected from withdrawal show" do
    withdrawal = Withdrawal.create!(user: @member, amount: 0.01, btc_address: "bc1qunauth2", status: :pending, requested_at: Time.current)
    get withdrawal_path(withdrawal)
    assert_redirected_to new_user_session_path
  end
end
