class AddIntegerDurationsToConnectionLinks < ActiveRecord::Migration
  def change
    add_column :connection_links, :default_duration, :integer
    add_column :connection_links, :frequent_traveller_duration, :integer
    add_column :connection_links, :occasional_traveller_duration, :integer
    add_column :connection_links, :mobility_restricted_traveller_duration, :integer
  end
end
