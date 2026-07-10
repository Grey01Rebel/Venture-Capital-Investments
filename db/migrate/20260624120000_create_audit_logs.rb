class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.string     :action,       null: false
      t.string     :subject_type
      t.bigint     :subject_id
      t.string     :ip_address
      t.jsonb      :metadata,     null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [:subject_type, :subject_id]
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
