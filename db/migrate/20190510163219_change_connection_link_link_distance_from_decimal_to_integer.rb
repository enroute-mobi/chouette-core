class ChangeConnectionLinkLinkDistanceFromDecimalToInteger < ActiveRecord::Migration
  def change
  	change_column :connection_links, :link_distance, :integer
  end
end
