class AddRetrievalFrequencyToSources < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :sources, :retrieval_frequency, :string

      Source.reset_column_information
      Source.where.not(enabled: true).update_all(retrieval_frequency: 'none')
      Source.where(enabled: true).update_all(retrieval_frequency: 'daily')

      remove_column :sources, :enabled, :boolean
    end
  end
end