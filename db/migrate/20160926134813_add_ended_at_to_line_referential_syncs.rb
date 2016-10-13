class AddEndedAtToLineReferentialSyncs < ActiveRecord::Migration
  def change
    add_column :line_referential_syncs, :ended_at, :datetime
  end
end
