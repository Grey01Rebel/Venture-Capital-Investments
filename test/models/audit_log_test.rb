require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  def setup
    @admin = create_confirmed_user
    @admin.update!(role: :admin)
  end

  def valid_attributes
    {
      action: "authorization.denied",
      actor:  @admin
    }
  end

  # Validity
  test "creates a valid audit log with all required attributes" do
    log = AuditLog.new(valid_attributes)
    assert log.valid?, "Expected log to be valid: #{log.errors.full_messages}"
  end

  test "is invalid without an action" do
    log = AuditLog.new(valid_attributes.merge(action: nil))
    assert_not log.valid?
    assert log.errors[:action].any?
  end

  test "is invalid with an action not in the known taxonomy" do
    log = AuditLog.new(valid_attributes.merge(action: "something.made_up"))
    assert_not log.valid?
    assert log.errors[:action].any?
  end

  test "is valid without an actor" do
    log = AuditLog.new(valid_attributes.merge(actor: nil))
    assert log.valid?
  end

  test "is valid without a subject" do
    log = AuditLog.new(valid_attributes)
    assert_nil log.subject
    assert log.valid?
  end

  # metadata defaults
  test "metadata defaults to an empty hash" do
    log = AuditLog.create!(valid_attributes)
    assert_equal({}, log.metadata)
  end

  test "metadata stores arbitrary jsonb content" do
    log = AuditLog.create!(valid_attributes.merge(metadata: { attempted_email: "someone@example.com" }))
    assert_equal "someone@example.com", log.reload.metadata["attempted_email"]
  end

  # Associations
  test "belongs to an actor" do
    log = AuditLog.create!(valid_attributes)
    assert_equal @admin, log.actor
  end

  test "belongs to a polymorphic subject" do
    log = AuditLog.create!(valid_attributes.merge(subject: @admin))
    assert_equal @admin, log.subject
    assert_equal "User", log.subject_type
  end

  test "user has many audit_logs as actor" do
    log = AuditLog.create!(valid_attributes)
    assert_includes @admin.audit_logs, log
  end

  test "deleting the actor nullifies actor_id rather than destroying the log" do
    log = AuditLog.create!(valid_attributes)
    @admin.destroy
    assert_nil log.reload.actor_id
  end

  # Immutability
  test "raises when attempting to update an existing log" do
    log = AuditLog.create!(valid_attributes)
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      log.update!(action: "user.signed_in")
    end
  end

  test "raises when attempting to destroy a log" do
    log = AuditLog.create!(valid_attributes)
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      log.destroy!
    end
  end

  test "log is unchanged after a failed update attempt" do
    log = AuditLog.create!(valid_attributes)
    assert_raises(ActiveRecord::ReadOnlyRecord) { log.update!(action: "user.signed_in") }
    assert_equal "authorization.denied", log.reload.action
  end

  # .record! entry point
  test "record! creates a log with the given attributes" do
    log = AuditLog.record!(action: "user.signed_in", actor: @admin, ip_address: "127.0.0.1")

    assert log.persisted?
    assert_equal "user.signed_in", log.action
    assert_equal @admin, log.actor
    assert_equal "127.0.0.1", log.ip_address
  end

  test "record! defaults actor, subject, ip_address, and metadata" do
    log = AuditLog.record!(action: "investment.completed")

    assert_nil log.actor
    assert_nil log.subject
    assert_nil log.ip_address
    assert_equal({}, log.metadata)
  end

  test "record! raises on an invalid action rather than silently failing" do
    assert_raises(ActiveRecord::RecordInvalid) do
      AuditLog.record!(action: "not.a.real.event")
    end
  end
end
