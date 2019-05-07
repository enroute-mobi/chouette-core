module Chouette::Netex::Concerns::EntityCollections
  def netex_operators
    Chouette::Company.within_workgroup(workgroup) do
      companies.find_each do |company|
        Chouette::Netex::Operator.new(self, company).to_xml(@builder)
      end
    end
  end

  def netex_stop_places
    Chouette::StopArea.within_workgroup(workgroup) do
      rows_count = 0
      collection = stop_areas.where('stop_areas.area_type != ? OR stop_areas.parent_id IS NULL', :zdep)
      total_rows = collection.count
      collection.includes(:parent).find_each do |stop_area|
        Chouette::Netex::StopPlace.new(self, stop_area, stop_areas).to_xml(@builder)
        rows_count += 1
        @export.notify_sub_operation_progress(:site_frame, rows_count.to_f/total_rows)
      end
    end
  end

  def netex_lines
    lines.includes(:network, :company_light).find_each do |line|
      Chouette::Netex::Line.new(self, line).to_xml(@builder)
    end
  end

  def netex_groups_of_lines
    networks.find_each do |network|
      Chouette::Netex::GroupOfLines.new(self, network).to_xml(@builder)
    end
  end

  def netex_routes
    routes.includes(:line, :stop_points, :opposite_route).find_each do |route|
      Chouette::Netex::Route.new(self, route).to_xml(@builder)
    end
  end

  def netex_scheduled_stop_points
    stop_points.light.find_each do |stop_point|
      Chouette::Netex::ScheduledStopPoint.new(self, stop_point).to_xml(@builder)
    end
  end

  def netex_stop_assignments
    stop_points.light.includes(:stop_area_light).find_each do |stop_point|
      Chouette::Netex::PassengerStopAssignment.new(self, stop_point).to_xml(@builder)
    end
  end

  def netex_route_points
    stop_points.includes(:stop_area_light).find_each do |stop_point|
      Chouette::Netex::RoutePoint.new(self, stop_point).to_xml(@builder)
    end
  end

  def netex_service_journey_patterns
    Chouette::JourneyPattern.within_workgroup(workgroup) do
      journey_patterns.includes(:route, :stop_point_lights).find_each do |journey_pattern|
        Chouette::Netex::ServiceJourneyPattern.new(self, journey_pattern).to_xml(@builder)
      end
    end
  end

  def netex_service_links
    Chouette::JourneyPattern.within_workgroup(workgroup) do
      journey_patterns.includes(:stop_point_lights).find_each do |journey_pattern|
        Chouette::Netex::ServiceLink.new(self, journey_pattern).to_xml(@builder)
      end
    end
  end

  def netex_day_types
    time_tables.includes(:tags).find_each do |time_table|
      Chouette::Netex::DayType.new(self, time_table).to_xml(@builder)
    end
  end

  def netex_operating_periods
    time_tables.includes(:periods).find_each do |time_table|
      Chouette::Netex::OperatingPeriod.new(self, time_table).to_xml(@builder)
    end
  end

  def netex_day_type_assignments
    time_tables.includes(:periods, :dates).find_each do |time_table|
      Chouette::Netex::DayTypeAssignment.new(self, time_table).to_xml(@builder)
    end
  end

  def netex_service_journeys
    Chouette::VehicleJourney.within_workgroup(workgroup) do
      vehicle_journeys\
      .includes(:journey_pattern_only_objectid, :company_light, :purchase_windows, :time_tables, vehicle_journey_at_stops: { stop_point: :stop_area_light })\
      .find_each do |vehicle_journey|
        Chouette::Netex::ServiceJourney.new(self, vehicle_journey).to_xml(@builder)
      end
    end
  end

  def netex_routing_constraint_zones
    routing_constraint_zones.includes(route: :line).find_each do |rcz|
      Chouette::Netex::RoutingConstraintZone.new(self, rcz).to_xml(@builder)
    end
  end
end
