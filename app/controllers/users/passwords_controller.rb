# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # POST /users/password — a reset token is requested.
  def create
    super do |resource|
      if resource.errors.empty?
        AuditLog.record!(
          action:     "user.password_reset_requested",
          subject:    resource,
          ip_address: request.remote_ip
        )
      end
    end
  end

  # PUT /users/password — the reset is completed with a valid token.
  def update
    super do |resource|
      if resource.errors.empty?
        AuditLog.record!(
          action:     "user.password_reset_completed",
          actor:      resource,
          subject:    resource,
          ip_address: request.remote_ip
        )
      end
    end
  end
end
