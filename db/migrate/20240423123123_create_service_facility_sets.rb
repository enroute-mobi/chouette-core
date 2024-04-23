class CreateServiceFacilitySets < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :service_facility_sets do |t|
        t.string :name
        t.string :associated_services, array: true, default: []
        t.references :referential

        t.timestamps
      end
    end
  end
end
