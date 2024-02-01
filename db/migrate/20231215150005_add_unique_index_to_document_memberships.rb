# frozen_string_literal: true

class AddUniqueIndexToDocumentMemberships < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_table :document_memberships do |t|
        t.index %i[documentable_type documentable_id document_id],
                unique: true,
                name: 'index_document_memberships_on_documentable_and_document_id'
      end
    end
  end
end
