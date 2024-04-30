# frozen_string_literal: true

class CreateServiceFacilitySets < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :service_facility_sets do |t|
        t.uuid :uuid, default: -> { 'gen_random_uuid()' }, null: false
        t.string :name
        t.string :associated_services, array: true, default: []
        t.references :shape_referential
        t.references :shape_provider

        t.timestamps
      end
    end

    add_column :vehicle_journeys, :service_facility_set_ids, :bigint, array: true, default: []
  end
end
