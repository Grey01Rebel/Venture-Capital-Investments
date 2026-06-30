class RenameReviewerIdToReviewedByIdOnWithdrawals < ActiveRecord::Migration[8.0]
  def change
    rename_column :withdrawals, :reviewer_id, :reviewed_by_id
  end
end