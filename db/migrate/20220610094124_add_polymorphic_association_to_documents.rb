class AddPolymorphicAssociationToDocuments < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :document_memberships do |t|
        t.bigint :documentable_id, null: false
        t.string :documentable_type, null: false
        t.references :document
      end
    end
  end
end
