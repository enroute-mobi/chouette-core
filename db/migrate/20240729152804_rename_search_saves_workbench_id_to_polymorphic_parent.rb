# frozen_string_literal: true

class RenameSearchSavesWorkbenchIdToPolymorphicParent < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      change_table :saved_searches do |t|
        t.remove_index name: 'index_saved_searches_on_workbench_id'

        t.rename :workbench_id, :parent_id
        t.string :parent_type, null: false, default: 'Workbench'

        t.index %i[parent_type parent_id]
      end

      change_column_default :saved_searches, :parent_type, nil
    end
  end

  def down
    on_public_schema_only do
      change_table :saved_searches do |t|
        t.remove :parent_type
        t.rename :parent_id, :workbench_id
        t.index :workbench_id
      end
    end
  end
end
