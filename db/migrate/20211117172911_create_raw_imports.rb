class CreateRawImports < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :raw_imports do |t|
        t.references :model, polymorphic: true, index: true
        t.string :model_type
        t.text :content

        t.timestamps
      end
    end
  end
end
