# frozen_string_literal: true

class RemoveRollbackInOperations < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      remove_column :publications, :rollback
    end
  end

  def down
    on_public_schema_only do
      add_column :publications, :rollback, :boolean
    end
  end
end
