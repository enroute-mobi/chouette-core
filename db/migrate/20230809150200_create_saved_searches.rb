class CreateSavedSearches < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :saved_searches do |t|
        t.references :workbench
        t.string :search_type, null: false
        t.string :name, null: false
        t.string :creator, null: false
        t.datetime :last_used_at, null: false
        t.jsonb :search_attributes, default: {}
        t.text :descriptions

        t.timestamps
      end
    end
  end
end
