class CreateDocumentsTypes < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :document_types do |t|
        t.references :workgroup

        t.string :name
        t.string :short_name
        t.string :description

        t.timestamps
      end
    end
  end
end
