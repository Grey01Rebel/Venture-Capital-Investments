class CreateDeposits < ActiveRecord::Migration[8.0]
  def change
    create_table :deposits do |t|
      t.references :user,            null: false, foreign_key: true
      t.references :investment_plan, null: false, foreign_key: true

      t.decimal  :amount_usd,        precision: 12, scale: 2, null: false
      t.decimal  :btc_amount,        precision: 20, scale: 8, null: false
      t.string   :transaction_hash,  null: false
      t.integer  :status,            null: false, default: 0
      t.datetime :submitted_at,      null: false

      t.timestamps
    end

    add_index :deposits, :transaction_hash, unique: true
    add_index :deposits, :status
  end
end