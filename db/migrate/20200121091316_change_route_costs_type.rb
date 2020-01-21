class ChangeRouteCostsType < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        change_column :routes, :costs, 'jsonb', using: 'costs::jsonb', default: {}
      end
      dir.down do
        change_column :routes, :costs, 'json', using: 'costs::json', default: {}
      end
    end
  end
end
