# frozen_string_literal: true
require "test_helper"

class AuthorizationAuditLogTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @owner       = create_confirmed_user
    @other_user  = create_confirmed_user
    @plan        = create_investment_plan(position: 1801)
    @deposit     = Deposit.create!(
      user:             @owner,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "authaudit#{SecureRandom.hex(28)}",
      submitted_at:     Time.current
    )
  end

  test "creates an authorization.denied audit log when a member views another member's deposit" do
    sign_in @other_user
    # Devise's test `sign_in` defers the actual Warden authentication event
    # to the next request (see Warden::Test::Helpers#login_as), which would
    # otherwise register as a spurious user.signed_in entry inside the
    # block below. Flush it here so we measure only the request under test.
    get authenticated_root_path

    assert_difference "AuditLog.count", 1 do
      get deposit_path(@deposit)
    end

    log = AuditLog.last
    assert_equal "authorization.denied", log.action
    assert_equal @other_user, log.actor
    assert_equal @deposit, log.subject
  end

  test "redirects to the authenticated root with an alert" do
    sign_in @other_user
    get deposit_path(@deposit)
    assert_redirected_to authenticated_root_path
    assert_equal "You are not authorised to perform that action.", flash[:alert]
  end

  test "does not create an audit log entry when the owner views their own deposit" do
    sign_in @owner
    get authenticated_root_path # flush the deferred sign_in event, as above

    assert_no_difference "AuditLog.count" do
      get deposit_path(@deposit)
    end
  end
end
