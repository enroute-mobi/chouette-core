class AddDaysOfWeekToSources < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :sources, :retrieval_days_of_week, :bit, limit: 7, default: "1111111"
    end
  end
end
