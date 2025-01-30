# frozen_string_literal: true

class RemoveLegacyColumnsInStopAreasAndReferentials < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      change_table :stop_areas do |t|
        t.remove :long_lat_type
        t.remove :nearest_topic_name
        t.remove :stif_type
      end

      change_table :referentials do |t|
        t.remove :projection_type
      end
    end
  end

  def down
    on_public_schema_only do
      change_table :stop_areas do |t|
        t.string :long_lat_type
        t.string :nearest_topic_name
        t.string :stif_type
      end

      change_table :referentials do |t|
        t.string :projection_type
      end
    end
  end
end
