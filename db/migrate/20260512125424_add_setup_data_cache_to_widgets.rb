# frozen_string_literal: true

class AddSetupDataCacheToWidgets < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      change_table :widgets do |t|
        t.jsonb :setup_data_cache
        t.datetime :setup_data_cache_updated_at
      end
    end
  end
end
