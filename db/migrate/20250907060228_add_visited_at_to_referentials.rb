class AddVisitedAtToReferentials < ActiveRecord::Migration[7.0]
  def change
    on_public_schema_only do
      add_column :referentials, :visited_at, :datetime
    end
  end
end
