class ChangeOptionSupportType < ActiveRecord::Migration[5.2]

  def up
    change_column :exports, :options, 'jsonb', using: 'options::hstore::jsonb', default: {}
    change_column :imports, :options, 'jsonb', using: 'options::hstore::jsonb', default: {}
    change_column :destinations, :options, 'jsonb', using: 'options::hstore::jsonb', default: {}
  end

  def down
    # Since json handles array management and apparently hstore doesn't, the reverse migration isn't possible
  end
end
