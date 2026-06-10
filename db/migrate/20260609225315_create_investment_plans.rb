class CreateInvestmentPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :investment_plans do |t|
      t.string  :name,                   null: false
      t.text    :description
      t.decimal :investment_amount_usd,  precision: 12, scale: 2, null: false
      t.decimal :daily_return_rate,      precision: 5,  scale: 2, null: false
      t.integer :duration_days,          null: false
      t.boolean :active,                 null: false, default: true
      t.integer :position,               null: false

      t.timestamps
    end

    add_index :investment_plans, :name,     unique: true
    add_index :investment_plans, :position, unique: true
    add_index :investment_plans, :active
  end
end