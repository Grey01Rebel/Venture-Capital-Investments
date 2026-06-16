class CreateInvestments < ActiveRecord::Migration[8.0]
  def change
    create_table :investments do |t|
      t.references :user,            null: false, foreign_key: true
      t.references :deposit,         null: false, foreign_key: true,  index: false
      t.references :investment_plan, null: false, foreign_key: true

      t.decimal :principal_amount,  precision: 12, scale: 2, null: false
      t.decimal :daily_return_rate, precision: 5,  scale: 2, null: false
      t.integer :duration_days,     null: false

      t.datetime :started_at, null: false
      t.datetime :ends_at,    null: false

      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :investments, :deposit_id, unique: true
    add_index :investments, :status
    add_index :investments, :started_at
    add_index :investments, :ends_at
  end
end