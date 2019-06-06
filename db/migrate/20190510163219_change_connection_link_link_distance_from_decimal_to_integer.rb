class ChangeConnectionLinkLinkDistanceFromDecimalToInteger < ActiveRecord::Migration[4.2]
  def up
  	change_column :connection_links, :link_distance, :integer
  end

  def down
  	change_column :connection_links, :link_distance, :decimal
  end
end
