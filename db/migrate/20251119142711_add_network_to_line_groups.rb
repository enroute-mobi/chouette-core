class AddNetworkToLineGroups < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      add_reference :line_groups, :network, null: true
    end
  end
end
