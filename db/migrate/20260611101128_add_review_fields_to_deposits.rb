class AddReviewFieldsToDeposits < ActiveRecord::Migration[8.0]
  def change
    add_column :deposits, :approved_at,     :datetime
    add_column :deposits, :rejected_at,     :datetime
    add_column :deposits, :admin_notes,     :text
    add_column :deposits, :reviewed_by_id,  :bigint

    add_foreign_key :deposits, :users, column: :reviewed_by_id
    add_index       :deposits, :reviewed_by_id
    add_index       :deposits, :approved_at
    add_index       :deposits, :rejected_at
  end
end