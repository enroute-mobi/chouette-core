class CreateSourceRetrievals < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :source_retrievals do |t|
        t.references :workbench
        t.references :source
        t.references :import

        t.string :status
        t.string :error_uuid
        t.string :creator
        t.datetime :started_at
        t.datetime :ended_at

        t.timestamps
      end
    end
  end
end
