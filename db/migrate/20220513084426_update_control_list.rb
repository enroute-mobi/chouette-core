class UpdateControlList < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :control_lists, :shared, :boolean, default: false
    end
  end
end
