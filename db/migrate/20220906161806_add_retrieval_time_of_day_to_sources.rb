class AddRetrievalTimeOfDayToSources < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :sources, :retrieval_time_of_day, :time, null: false
    end
  end
end