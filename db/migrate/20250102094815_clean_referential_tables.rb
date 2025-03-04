class CleanReferentialTables < ActiveRecord::Migration[5.2]
  def change
    # routes
    remove_column :routes, :comment
    remove_column :routes, :number
    remove_column :routes, :direction
    change_column :routes, :line_id, :bigint, null: false

    # stop_points
    change_column :stop_points, :route_id, :bigint, null: false
    change_column :stop_points, :stop_area_id, :bigint, null: false
    change_column :stop_points, :position, :integer, null: false

    # journey_patterns
    remove_column :journey_patterns, :comment
    change_column :journey_patterns, :route_id, :bigint, null: false

    # journey_patterns_stop_points
    change_column :journey_patterns_stop_points, :journey_pattern_id, :bigint, null: false
    change_column :journey_patterns_stop_points, :stop_point_id, :bigint, null: false

    # time_tables
    remove_column :time_tables, :version

    # time_tables_vehicle_journeys
    change_column :time_tables_vehicle_journeys, :time_table_id, :bigint, null: false
    change_column :time_tables_vehicle_journeys, :vehicle_journey_id, :bigint, null: false

    # vehicle_journeys
    remove_column :vehicle_journeys, :comment
    remove_column :vehicle_journeys, :facility
    remove_column :vehicle_journeys, :vehicle_type_identifier
    remove_column :vehicle_journeys, :number
    remove_column :vehicle_journeys, :mobility_restricted_suitability
    remove_column :vehicle_journeys, :flexible_service
    remove_column :vehicle_journeys, :journey_category
    change_column :vehicle_journeys, :journey_pattern_id, :bigint, null: false
    change_column :vehicle_journeys, :route_id, :bigint, null: false

    # vehicle_journey_at_stops
    remove_column :vehicle_journey_at_stops, :connecting_service_id
    remove_column :vehicle_journey_at_stops, :boarding_alighting_possibility
    remove_column :vehicle_journey_at_stops, :for_boarding
    remove_column :vehicle_journey_at_stops, :for_alighting
    change_column :vehicle_journey_at_stops, :vehicle_journey_id, :bigint, null: false
    change_column :vehicle_journey_at_stops, :stop_point_id, :bigint, null: false

    # routing_constraint_zones
    change_column :routing_constraint_zones, :route_id, :bigint, null: false

    # service_counts
    change_column :service_counts, :line_id, :bigint, null: false
    change_column :service_counts, :route_id, :bigint, null: false
    change_column :service_counts, :journey_pattern_id, :bigint, null: false
    change_column :service_counts, :date, :date, null: false
    change_column :service_counts, :count, :integer, null: false

    # footnotes
    change_column :footnotes, :line_id, :bigint, null: false

    # footnotes_vehicle_journeys
    change_column :footnotes_vehicle_journeys, :vehicle_journey_id, :bigint, null: false
    change_column :footnotes_vehicle_journeys, :footnote_id, :bigint, null: false


  end
end
