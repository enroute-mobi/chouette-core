# frozen_string_literal: true

class AddPreferReferentDocumentsToPublicationApi < ActiveRecord::Migration[7.0]
  def change
    on_public_schema_only do
      change_table :publication_apis do |t|
        t.boolean :prefer_referent_documents, null: false, default: false
      end
    end
  end
end
