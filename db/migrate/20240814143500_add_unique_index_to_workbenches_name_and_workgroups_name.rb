# frozen_string_literal: true

class AddUniqueIndexToWorkbenchesNameAndWorkgroupsName < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      change_table :workgroups do |t|
        t.index %i[owner_id name], unique: true
      end

      change_table :workbenches do |t|
        t.remove_index name: 'index_workbenches_on_workgroup_id'
        t.index %i[workgroup_id name], unique: true
      end
    end
  end

  def down
    on_public_schema_only do
      change_table :workgroups do |t|
        t.remove_index name: 'index_workgroups_on_owner_id_and_name'
      end

      change_table :workbenches do |t|
        t.remove_index name: 'index_workbenches_on_workgroup_id_and_name'
        t.index %i[workgroup_id]
      end
    end
  end
end
