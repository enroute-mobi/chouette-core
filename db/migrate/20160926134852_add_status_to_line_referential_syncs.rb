class AddStatusToLineReferentialSyncs < ActiveRecord::Migration
  def change
    add_column :line_referential_syncs, :status, :string
  end
end
