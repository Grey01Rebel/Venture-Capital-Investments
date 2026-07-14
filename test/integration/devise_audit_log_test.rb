# frozen_string_literal: true
require "test_helper"

class DeviseAuditLogTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_confirmed_user(password: "password123", password_confirmation: "password123")
  end

  test "creates a user.signed_in audit log entry on successful sign in" do
    assert_difference "AuditLog.count", 1 do
      post user_session_path, params: { user: { email: @user.email, password: "password123" } }
    end

    log = AuditLog.last
    assert_equal "user.signed_in", log.action
    assert_equal @user, log.actor
  end

  test "creates a user.sign_in_failed audit log entry for a wrong password" do
    assert_difference "AuditLog.count", 1 do
      post user_session_path, params: { user: { email: @user.email, password: "wrongpassword" } }
    end

    log = AuditLog.last
    assert_equal "user.sign_in_failed", log.action
    assert_nil log.actor
    assert_equal @user.email, log.metadata["attempted_email"]
  end

  test "does not create an audit log entry for an anonymous visit to a protected page" do
    assert_no_difference "AuditLog.count" do
      get "/plans"
    end
  end

  test "creates a user.signed_out audit log entry on sign out" do
    sign_in @user
    # See the comment in authorization_audit_log_test.rb: sign_in's actual
    # Warden authentication event is deferred to the next request. Flush
    # it here so only the sign-out itself is measured below.
    get authenticated_root_path

    assert_difference "AuditLog.count", 1 do
      delete destroy_user_session_path
    end

    log = AuditLog.last
    assert_equal "user.signed_out", log.action
    assert_equal @user, log.actor
  end

  test "creates a user.password_reset_requested audit log entry for a known email" do
    assert_difference "AuditLog.count", 1 do
      post user_password_path, params: { user: { email: @user.email } }
    end

    log = AuditLog.last
    assert_equal "user.password_reset_requested", log.action
    assert_equal @user, log.subject
  end

  test "does not create an audit log entry when requesting a reset for an unknown email" do
    assert_no_difference "AuditLog.count" do
      post user_password_path, params: { user: { email: "unknown@example.com" } }
    end
  end

  test "creates a user.password_reset_completed audit log entry on successful reset" do
    raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
    @user.update!(reset_password_token: hashed_token, reset_password_sent_at: Time.current)

    # Whether this additionally fires user.signed_in depends on Devise's
    # sign_in_after_reset_password setting, which this test doesn't own or
    # control. Assert on the event this controller is actually responsible
    # for, rather than on that optional side effect.
    assert_difference "AuditLog.where(action: 'user.password_reset_completed').count", 1 do
      put user_password_path, params: {
        user: {
          reset_password_token:  raw_token,
          password:              "newpassword123",
          password_confirmation: "newpassword123"
        }
      }
    end

    completed_log = AuditLog.find_by(action: "user.password_reset_completed")
    assert_equal @user, completed_log.actor
    assert_equal @user, completed_log.subject
  end

  test "does not create a password_reset_completed audit log entry for an invalid token" do
    assert_no_difference "AuditLog.count" do
      put user_password_path, params: {
        user: {
          reset_password_token:  "not-a-real-token",
          password:              "newpassword123",
          password_confirmation: "newpassword123"
        }
      }
    end
  end
end
