class RemoveAttributesToLines < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      remove_column :lines, :int_user_needs
      remove_column :lines, :stable_id
    end
  end
end
