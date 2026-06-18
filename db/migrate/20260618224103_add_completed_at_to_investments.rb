class AddCompletedAtToInvestments < ActiveRecord::Migration[8.0]
  def change
    add_column :investments, :completed_at, :datetime
    add_index  :investments, :completed_at
  end
end