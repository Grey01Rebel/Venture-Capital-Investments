# frozen_string_literal: true
require "test_helper"

class CreateWithdrawalsMigrationTest < ActiveSupport::TestCase
  test "withdrawals table exists" do
    assert ActiveRecord::Base.connection.table_exists?(:withdrawals)
  end

  test "withdrawals table has expected columns" do
    columns = ActiveRecord::Base.connection.columns(:withdrawals).map(&:name)

    %w[
    user_id reviewed_by_id amount btc_address status
    requested_at approved_at rejected_at completed_at
    admin_notes created_at updated_at
  ].each do |expected_column|
      assert_includes columns, expected_column, "Expected withdrawals table to have column: #{expected_column}"
    end
  end

  test "amount column is decimal with 8 decimal places" do
    column = ActiveRecord::Base.connection.columns(:withdrawals).find { |c| c.name == "amount" }
    assert_equal :decimal, column.type
    assert_equal 8, column.scale
  end

  test "status column defaults to 0 (pending)" do
    column = ActiveRecord::Base.connection.columns(:withdrawals).find { |c| c.name == "status" }
    assert_equal "0", column.default
  end

  test "user_id has a not-null constraint" do
    column = ActiveRecord::Base.connection.columns(:withdrawals).find { |c| c.name == "user_id" }
    assert_not column.null
  end

  test "reviewed_by_id is nullable" do
    column = ActiveRecord::Base.connection.columns(:withdrawals).find { |c| c.name == "reviewed_by_id" }
    assert column.null
  end

  test "an index exists on status" do
    indexes = ActiveRecord::Base.connection.indexes(:withdrawals)
    assert indexes.any? { |i| i.columns == ["status"] }
  end
end
