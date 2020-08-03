class ChangeJourneyPatternsCostsType < ActiveRecord::Migration[5.2]
  def up
    change_column :journey_patterns, :costs, 'jsonb', using: 'costs::jsonb', default: {}
  end
  def down
    change_column :journey_patterns, :costs, 'json', using: 'costs::json', default: {}
  end
end
