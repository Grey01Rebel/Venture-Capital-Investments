# frozen_string_literal: true
require "test_helper"

class CreateAuditLogsMigrationTest < ActiveSupport::TestCase
  test "audit_logs table exists" do
    assert ActiveRecord::Base.connection.table_exists?(:audit_logs)
  end

  test "audit_logs table has expected columns" do
    columns = ActiveRecord::Base.connection.columns(:audit_logs).map(&:name)

    %w[
      actor_id action subject_type subject_id
      ip_address metadata created_at
    ].each do |expected_column|
      assert_includes columns, expected_column, "Expected audit_logs table to have column: #{expected_column}"
    end
  end

  test "audit_logs table has no updated_at column" do
    columns = ActiveRecord::Base.connection.columns(:audit_logs).map(&:name)
    assert_not_includes columns, "updated_at"
  end

  test "action column is not nullable" do
    column = ActiveRecord::Base.connection.columns(:audit_logs).find { |c| c.name == "action" }
    assert_not column.null
  end

  test "actor_id is nullable" do
    column = ActiveRecord::Base.connection.columns(:audit_logs).find { |c| c.name == "actor_id" }
    assert column.null
  end

  test "metadata column is jsonb defaulting to an empty object" do
    column = ActiveRecord::Base.connection.columns(:audit_logs).find { |c| c.name == "metadata" }
    assert_equal :jsonb, column.type
    assert_not column.null
  end

  test "an index exists on action" do
    indexes = ActiveRecord::Base.connection.indexes(:audit_logs)
    assert indexes.any? { |i| i.columns == ["action"] }
  end

  test "an index exists on subject_type and subject_id" do
    indexes = ActiveRecord::Base.connection.indexes(:audit_logs)
    assert indexes.any? { |i| i.columns == ["subject_type", "subject_id"] }
  end
end
