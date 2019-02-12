module Chouette::Netex::Concerns::EntityCollections
  def netex_operators(builder)
    Chouette::Company.within_workgroup(referential.workgroup) do
      companies.find_each do |company|
        Chouette::Netex::Operator.new(company).to_xml(builder)
      end
    end
  end

  def netex_stop_places(builder)
    Chouette::StopArea.within_workgroup(referential.workgroup) do
      stop_areas.where('stop_areas.area_type != ? OR stop_areas.parent_id IS NULL', :zdep).includes(:parent).find_each do |stop_area|
        Chouette::Netex::StopPlace.new(stop_area, stop_areas).to_xml(builder)
      end
    end
  end

  def netex_lines(builder)
    lines.find_each do |line|
      Chouette::Netex::Line.new(line).to_xml(builder)
    end
  end

  def netex_groups_of_lines(builder)
    networks.find_each do |network|
      Chouette::Netex::GroupOfLines.new(network).to_xml(builder)
    end
  end

  def netex_routes(builder)
    routes.find_each do |route|
      Chouette::Netex::Route.new(route).to_xml(builder)
    end
  end

  def netex_scheduled_stop_points(builder)
    stop_points.select(:id, :objectid).find_each do |stop_point|
      Chouette::Netex::ScheduledStopPoint.new(stop_point).to_xml(builder)
    end
  end

  def netex_stop_assignements(builder)
    stop_points.includes(:stop_area_light).find_each do |stop_point|
      Chouette::Netex::PassengerStopAssignment.new(stop_point).to_xml(builder)
    end
  end

  def netex_route_points(builder)
    stop_points.includes(:stop_area_light).find_each do |stop_point|
      Chouette::Netex::RoutePoint.new(stop_point).to_xml(builder)
    end
  end
end
