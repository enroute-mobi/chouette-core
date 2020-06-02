class ChangeOptionSupportType < ActiveRecord::Migration[5.2]

  def up
    on_public_schema_only do
      change_column :exports, :options, 'jsonb', using: 'options::hstore::jsonb', default: {}
      change_column :imports, :options, 'jsonb', using: 'options::hstore::jsonb', default: {}
      change_column :destinations, :options, 'jsonb', using: 'options::hstore::jsonb', default: {}
    end
  end

  def down
    # Since json handles array management and apparently hstore doesn't, the reverse migration isn't possible
  end
end
