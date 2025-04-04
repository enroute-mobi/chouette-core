# frozen_string_literal: true

# List conditionnal features
class Feature
  def self.base
    %w[
      core_control_blocks
      create_opposite_routes
      create_referential_from_merge
      detailed_calendars
      import_netex_store_xml
      journey_length_in_vehicle_journeys
      long_distance_routes
      purge_merged_data
      route_stop_areas_all_types
      stop_area_connection_links
      stop_area_localized_names
      stop_area_routing_constraints
      stop_area_waiting_time
      vehicle_journeys_return_route
    ]
  end

  mattr_accessor :additionals, default: Chouette::Config.additional_features

  def self.all
    @all ||= (base + additionals).uniq
  end
end
