# frozen_string_literal: true
require "test_helper"

class WithdrawalMailerTest < ActionMailer::TestCase
  def setup
    @user  = create_confirmed_user(full_name: "Jane Investor")
    @admin = create_confirmed_user
    @admin.update!(role: :admin)
    @user.wallet.update!(available_balance: 0.04000000)

    @withdrawal = Withdrawal.create!(
      user:           @user,
      amount:         0.01000000,
      btc_address:    "bc1qmailertest",
      status:         :completed,
      requested_at:   1.hour.ago,
      approved_at:    30.minutes.ago,
      completed_at:   Time.current,
      transaction_hash: "mailertxhash#{SecureRandom.hex(8)}",
      reviewed_by_id: @admin.id
    )
  end

  test "completed email is sent to the withdrawing user" do
    mail = WithdrawalMailer.completed(@withdrawal)

    assert_equal [@user.email], mail.to
    assert_equal "Your withdrawal has been completed", mail.subject
  end

  test "completed email body includes the btc address" do
    mail = WithdrawalMailer.completed(@withdrawal)

    assert_match @withdrawal.btc_address, mail.body.encoded
  end

  test "completed email body includes the transaction hash" do
    mail = WithdrawalMailer.completed(@withdrawal)

    assert_match @withdrawal.transaction_hash, mail.body.encoded
  end
end
