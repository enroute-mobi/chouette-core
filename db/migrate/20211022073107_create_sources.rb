class CreateSources < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table "sources" do |t|
        t.string :name
        t.references :workbench
        t.string :url
        t.string :downloader_type
        t.jsonb :downloader_options, default: {}
        t.string :checksum
        t.jsonb :import_options, default: {}
        t.timestamps
      end
    end
  end
end
