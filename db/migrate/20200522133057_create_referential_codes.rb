class CreateReferentialCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :referential_codes do |t|
      t.references :resource, polymorphic: true
      t.string :value, null: false

      t.index [:resource_type, :resource_id, :value], name: 'index_referential_codes_on_resource_and_value', unique: true
    end
  end
end
