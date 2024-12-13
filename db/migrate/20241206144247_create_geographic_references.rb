# frozen_string_literal: true

class CreateGeographicReferences < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :fare_geographic_references do |t|
        t.string :short_name, null: false
        t.string :name
        t.references :fare_zone

        t.timestamps
      end
    end
  end
end
