class AddPriorityToWorkbenches < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :workbenches, :priority, :integer, default: 1
    end
  end
end
