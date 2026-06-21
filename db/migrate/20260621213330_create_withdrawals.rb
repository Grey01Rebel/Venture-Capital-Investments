class CreateWithdrawals < ActiveRecord::Migration[8.0]
  def change
    create_table :withdrawals do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :reviewer, foreign_key: { to_table: :users }, null: true

      t.decimal :amount, precision: 20, scale: 8, null: false
      t.string  :btc_address, null: false
      t.integer :status, null: false, default: 0

      t.datetime :requested_at
      t.datetime :approved_at
      t.datetime :rejected_at
      t.datetime :completed_at

      t.text :admin_notes

      t.timestamps
    end

    add_index :withdrawals, :status
  end
end