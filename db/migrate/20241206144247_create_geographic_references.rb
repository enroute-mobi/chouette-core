# frozen_string_literal: true

class CreateGeographicReferences < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :fare_geographic_references do |t|
        t.string :short_name, null: false
        t.string :name

        t.references :fare_zone, null: false, index: false
        t.index %i[fare_zone_id short_name], unique: true

        t.timestamps
      end
    end
  end
end
