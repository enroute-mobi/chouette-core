class AddStartedAtToLineReferentialSyncs < ActiveRecord::Migration
  def change
    add_column :line_referential_syncs, :started_at, :datetime
  end
end
