class RollbackExportOptionsColumnTypeChange < ActiveRecord::Migration[5.2]

  # This is possible because, so far, the options column in export table hasn't yet had to manage array storage

  def up
    on_public_schema_only do
      rename_column :exports, :options, :options_jsonb
      add_column    :exports, :options, :hstore, default: {}
      execute       'UPDATE "exports" SET "options" = (SELECT hstore(array_agg(key), array_agg(value)) FROM jsonb_each_text("options_jsonb"))'
      remove_column :exports, :options_jsonb
    end
  end

  def down
    on_public_schema_only do
      # The cast from hstore to jsonb fails if the default value isn't removed
      change_column_default :exports, :options, nil
      change_column :exports, :options, 'jsonb', using: 'options::hstore::jsonb', default: {}
    end
  end
end
