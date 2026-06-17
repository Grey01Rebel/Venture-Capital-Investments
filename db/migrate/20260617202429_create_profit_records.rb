class CreateProfitRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :profit_records do |t|
      t.references :user,       null: false, foreign_key: true
      t.references :investment, null: false, foreign_key: true, index: false

      t.decimal :amount,      precision: 12, scale: 2, null: false
      t.date    :profit_date, null: false

      t.timestamps
    end

    add_index :profit_records, [:investment_id, :profit_date], unique: true
  end
end