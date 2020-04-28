class AddRestrictionsToWorkbenches < ActiveRecord::Migration[5.2]
  def change
    add_column :workbenches, :restrictions, :string, array: true, default: []
  end
end
