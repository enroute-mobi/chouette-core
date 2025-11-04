# frozen_string_literal: true

class DropCustomFieldsAndCustomFieldGroups < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    on_public_schema_only do
      drop_table :custom_fields do |t|
        t.string "code"
        t.string "resource_type"
        t.string "name"
        t.string "field_type"
        t.json "options"
        t.bigint "workgroup_id"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
        t.integer :position, null: false
        t.references :custom_field_group, foreign_key: true
        t.index ["resource_type"], name: "index_custom_fields_on_resource_type"
        t.index [:workgroup_id, :resource_type, :custom_field_group_id, :position], :unique => true, name: 'uniq_workgroup_id_resource_type_custom_field_group_id_position'
      end

      drop_table :custom_field_groups do |t|
        t.references :workgroup

        t.string :name
        t.integer :position
        t.string :resource_type
        t.index [ :workgroup_id, :resource_type, :position ], unique: true, name: 'uniq_workgroup_id_and_resource_type_and_position'

        t.timestamps
      end
    end
  end
end
