class CreateWallets < ActiveRecord::Migration[8.0]
  def change
    create_table :wallets do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.decimal :available_balance, precision: 20, scale: 8, null: false, default: "0.0"
      t.decimal :total_deposited,   precision: 20, scale: 8, null: false, default: "0.0"
      t.decimal :total_withdrawn,   precision: 20, scale: 8, null: false, default: "0.0"
      t.decimal :total_profit,      precision: 20, scale: 8, null: false, default: "0.0"

      t.timestamps
    end
  end
end