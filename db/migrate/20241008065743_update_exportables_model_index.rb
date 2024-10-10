# frozen_string_literal: true

class UpdateExportablesModelIndex < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      remove_index :exportables, name: 'index_exportables_on_export_id'
      add_index :exportables, %i[export_id model_type model_id], unique: true
    end
  end

  def down
    on_public_schema_only do
      remove_index :exportables, name: 'index_exportables_on_export_id_and_model_type_and_model_id'
      add_index :exportables, [:export_id]
    end
  end
end
