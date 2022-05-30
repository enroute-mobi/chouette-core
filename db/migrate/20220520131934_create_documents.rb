class CreateDocuments < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :document_providers do |t|
        t.string :name, null: false
        t.references :workbench
        t.timestamps
      end

      create_table :documents do |t|
        t.uuid :uuid, default: -> { "gen_random_uuid()" }, null: false
        t.string :name, null: false
        t.text :description
        t.daterange :validity_period
        t.string :file, null: false
        t.references :document_type
        t.references :document_provider
        t.timestamps
      end

      reversible do |dir|
        dir.up { Workbench.find_each(&:create_default_document_provider) }
      end
    end
  end
end
