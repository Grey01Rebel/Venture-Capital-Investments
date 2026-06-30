class AddTransactionHashToWithdrawals < ActiveRecord::Migration[8.0]
  def change
    add_column :withdrawals, :transaction_hash, :string
    add_index  :withdrawals, :transaction_hash, unique: true, where: "transaction_hash IS NOT NULL"
  end
end