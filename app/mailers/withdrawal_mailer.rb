# frozen_string_literal: true
class WithdrawalMailer < ApplicationMailer
  # Sent when a withdrawal has been paid out on-chain. Approval and
  # rejection are not notified — completion is the event members care
  # about, since it's the actual movement of funds.
  def completed(withdrawal)
    @withdrawal = withdrawal
    @user       = withdrawal.user

    mail(
      to:      @user.email,
      subject: "Your withdrawal has been completed"
    )
  end
end
