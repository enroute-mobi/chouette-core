object @vehicle_journey

[:objectid, :published_journey_name, :published_journey_identifier, :company_id, :comment, :checksum, :custom_fields, :ignored_routing_contraint_zone_ids, :ignored_stop_area_routing_constraint_ids].each do |attr|
  attributes attr, :unless => lambda { |m| m.send( attr).nil?}
end

node { |vj| {short_id: vj.get_objectid.short_id} }

child(:codes, :object_root => false ) do |codes|
  attributes :id, :code_space_id, :resource_id, :value
end

child(:company) do |company|
  attributes :id, :objectid, :name
end

child(:route) do |route|
  child(:line) do |line|
    attributes :transport_mode, :transport_submode
  end
end

child(:journey_pattern) do |journey_pattern|
  attributes :id, :objectid, :name, :published_name, :journey_length
  node(:short_id) {journey_pattern.get_objectid.short_id}
  child(:stop_point_lights, :object_root => false) do |stop_points|
    attributes :id, :name, :objectid, :stop_area_id
  end
  attributes :available_specific_stop_places
end

child(:time_tables, :object_root => false) do |time_tables|
  attributes :id, :objectid, :comment, :color
  node(:days) do |tt|
    tt.display_day_types
  end
  node(:bounding_dates) do |tt|
    tt.presenter.time_table_bounding
  end
  child(:calendar) do
    attributes :id, :name, :date_ranges, :dates, :shared
  end
end

child :line_notices, :object_root => false do |line_notice|
  node(:code) { |line_notice| line_notice.title }
  node(:label) { |line_notice| line_notice.content }
  node(:id) { |line_notice| line_notice.id }
  node(:line_notice) { true }
end

child :footnotes, :object_root => false do
  attributes :id, :code, :label
end

child(:vehicle_journey_at_stops_matrix, :object_root => false) do |vehicle_stops|
  attributes :id, :connecting_service_id, :boarding_alighting_possibility, :stop_point_id
  node do |vehicle_stop|

    node(:dummy) { vehicle_stop.dummy }
    node(:area_kind) { vehicle_stop.stop_point.stop_area.kind }

    node(:specific_stop_area_id) do
      vehicle_stop.stop_area_id
    end

    node(:stop_area_object_id) do
      vehicle_stop.stop_point.stop_area.objectid
    end
    node(:stop_point_objectid) do
      vehicle_stop.stop_point.objectid
    end
    node(:stop_area_id) do
      vehicle_stop.stop_point.stop_area.id
    end
    node(:stop_area_name) do
      vehicle_stop.stop_point.stop_area.name
    end
    node(:stop_area_cityname) do
      vehicle_stop.stop_point.stop_area.city_name
    end

    [:arrival, :departure].each do |att|
      node("#{att}_time") do |vs|
        time_of_day = vs.send("#{att}_local_time_of_day")
        {
          hour: time_of_day&.hour&.to_s,
          minute: time_of_day&.minute&.to_s
        }
      end
    end
  end
end
