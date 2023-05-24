class CreateExportables < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :exportables do |t|
        t.references :export
        t.string :uuid
        t.references :model, polymorphic: true, index: false
        t.index %i[uuid model_type]
      end
    end
  end
end
