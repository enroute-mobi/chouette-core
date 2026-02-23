# frozen_string_literal: true

class AddIndexOnCodesAndReferentialCodesValue < ActiveRecord::Migration[7.2]
  def up
    on_public_schema_only do
      change_table :codes do |t|
        t.index %i[code_space_id resource_type value]
        t.remove_index name: 'index_codes_on_space_and_resource'
        t.remove_index name: 'index_codes_on_code_space_id'
      end
    end

    change_table :referential_codes do |t|
      t.index %i[code_space_id resource_type value], name: 'idx_on_code_space_id_resource_type_value'
      t.remove_index name: 'index_referential_codes_on_space_and_resource'
      t.remove_index name: 'index_referential_codes_on_code_space_id'
    end
  end

  def down
    on_public_schema_only do
      change_table :codes do |t|
        t.remove_index %i[code_space_id resource_type value]
        t.index %i[code_space_id resource_type resource_id], name: 'index_codes_on_space_and_resource'
        t.index :code_space_id, name: 'index_codes_on_code_space_id'
      end
    end

    change_table :referential_codes do |t|
      t.remove_index name: 'idx_on_code_space_id_resource_type_value'
      t.index %i[code_space_id resource_type resource_id], name: 'index_referential_codes_on_space_and_resource'
      t.index :code_space_id, name: 'index_referential_codes_on_code_space_id'
    end
  end
end
