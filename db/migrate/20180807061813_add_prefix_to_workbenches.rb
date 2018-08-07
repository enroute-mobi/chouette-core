class AddPrefixToWorkbenches < ActiveRecord::Migration
  def change
    add_column :workbenches, :prefix, :string
  end
end
