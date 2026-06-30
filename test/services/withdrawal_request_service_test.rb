# frozen_string_literal: true
require "test_helper"

class WithdrawalRequestServiceTest < ActiveSupport::TestCase
  def setup
    @user   = create_confirmed_user
    @wallet = @user.wallet
    @wallet.update!(available_balance: 0.05000000)
  end

  def call_service(amount:, btc_address: "bc1qtestaddress1234567890abcdef")
    WithdrawalRequestService.new(user: @user, amount: amount, btc_address: btc_address).call
  end

  # --- successful submission ---

  test "creates a withdrawal record on success" do
    assert_difference "Withdrawal.count", 1 do
      call_service(amount: 0.01000000)
    end
  end

  test "withdrawal defaults to pending status" do
    result = call_service(amount: 0.01000000)
    assert result.withdrawal.pending?
  end

  test "withdrawal is associated with the correct user" do
    result = call_service(amount: 0.01000000)
    assert_equal @user, result.withdrawal.user
  end

  test "withdrawal amount matches the requested amount" do
    result = call_service(amount: 0.01000000)
    assert_equal 0.01000000, result.withdrawal.amount
  end

  test "withdrawal btc_address matches the submitted address" do
    result = call_service(amount: 0.01000000, btc_address: "bc1qcustomaddress")
    assert_equal "bc1qcustomaddress", result.withdrawal.btc_address
  end

  test "requested_at is set server-side" do
    result = call_service(amount: 0.01000000)
    assert_not_nil result.withdrawal.requested_at
  end

  test "reduces wallet available_balance by the requested amount" do
    call_service(amount: 0.01000000)
    @wallet.reload
    assert_equal 0.04000000, @wallet.available_balance
  end

  test "returns a successful result object" do
    result = call_service(amount: 0.01000000)
    assert result.success?
    assert_instance_of Withdrawal, result.withdrawal
    assert_nil result.error
  end

  test "allows a withdrawal of the entire available balance" do
    result = call_service(amount: 0.05000000)
    assert result.success?
    @wallet.reload
    assert_equal 0, @wallet.available_balance
  end

  # --- amount validation ---

  test "returns failure for a zero amount" do
    result = call_service(amount: 0)
    assert_not result.success?
    assert_equal "Amount must be greater than zero.", result.error
  end

  test "returns failure for a negative amount" do
    result = call_service(amount: -0.01)
    assert_not result.success?
    assert_equal "Amount must be greater than zero.", result.error
  end

  test "returns failure for a blank amount" do
    result = call_service(amount: nil)
    assert_not result.success?
    assert_equal "Amount must be greater than zero.", result.error
  end

  test "creates nothing for an invalid amount" do
    assert_no_difference "Withdrawal.count" do
      call_service(amount: 0)
    end
  end

  test "wallet unchanged for an invalid amount" do
    original_balance = @wallet.available_balance
    call_service(amount: -1)
    @wallet.reload
    assert_equal original_balance, @wallet.available_balance
  end

  # --- insufficient balance ---

  test "returns failure when amount exceeds available balance" do
    result = call_service(amount: 0.10000000)
    assert_not result.success?
    assert_equal "Insufficient balance.", result.error
  end

  test "creates nothing when balance is insufficient" do
    assert_no_difference "Withdrawal.count" do
      call_service(amount: 0.10000000)
    end
  end

  test "wallet unchanged when balance is insufficient" do
    original_balance = @wallet.available_balance
    call_service(amount: 0.10000000)
    @wallet.reload
    assert_equal original_balance, @wallet.available_balance
  end

  test "returns failure when amount exceeds balance by a tiny margin" do
    result = call_service(amount: 0.05000001)
    assert_not result.success?
    assert_equal "Insufficient balance.", result.error
  end

  # --- missing wallet ---

  test "returns failure when wallet is missing" do
    @wallet.destroy
    result = call_service(amount: 0.01000000)
    assert_not result.success?
    assert_equal "Wallet not found.", result.error
  end

  # --- atomicity / rollback ---

  test "wallet remains unchanged if withdrawal creation fails" do
    original_balance = @wallet.available_balance

    Withdrawal.define_singleton_method(:create!) do |*args|
      raise ActiveRecord::RecordInvalid.new(Withdrawal.new)
    end

    result = call_service(amount: 0.01000000)

    assert_not result.success?
    @wallet.reload
    assert_equal original_balance, @wallet.available_balance
  ensure
    Withdrawal.singleton_class.send(:remove_method, :create!)
  end

  test "no withdrawal persisted if wallet update fails" do
    original_method = Wallet.instance_method(:update!)
    Wallet.define_method(:update!) { |*args| raise ActiveRecord::RecordInvalid.new(self) }

    assert_no_difference "Withdrawal.count" do
      call_service(amount: 0.01000000)
    end
  ensure
    Wallet.define_method(:update!, original_method)
  end

  # --- multiple sequential withdrawals correctly reduce balance ---

  test "sequential withdrawals each correctly reduce available balance" do
    call_service(amount: 0.01000000)
    call_service(amount: 0.01000000)
    @wallet.reload
    assert_equal 0.03000000, @wallet.available_balance
  end

  test "second withdrawal fails once balance is exhausted by the first" do
    call_service(amount: 0.05000000)
    result = call_service(amount: 0.00000001)
    assert_not result.success?
    assert_equal "Insufficient balance.", result.error
  end
end
