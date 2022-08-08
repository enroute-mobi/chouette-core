class AddRollbackToPublication < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :publications, :rollback, :boolean
    end
  end
end
