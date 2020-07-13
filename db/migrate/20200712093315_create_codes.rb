class CreateCodes < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :codes do |t|
        t.belongs_to :code_space, null: false
        t.belongs_to :resource, polymorphic: true, null: false
        t.string :value, null: false

        t.index [ :code_space_id, :resource_type, :resource_id ], name: 'index_codes_on_space_and_resource'
        t.index [ :code_space_id, :resource_type, :resource_id, :value ], name: 'index_codes_on_space_resource_and_value', unique: true

        t.timestamps
      end
    end
  end
end
