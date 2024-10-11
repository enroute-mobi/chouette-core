# frozen_string_literal: true

class AddEnableCacheToPublicationSetups < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :publication_setups, :enable_cache, :boolean, default: false, null: false
    end
  end
end
