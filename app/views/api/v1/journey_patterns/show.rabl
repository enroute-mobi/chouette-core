object @journey_pattern
extends "api/v1/trident_objects/show"
[:id, :name, :published_name, :registration_number, :comment, :checksum, :custom_fields, :shape_id].each do |attr|
  attributes attr, :unless => lambda { |m| m.send( attr).nil?}
end
node :full_schedule do |journey_pattern|
  journey_pattern.full_schedule?
end
if has_feature? :costs_in_journey_patterns
  attribute :costs
end
node(:route_short_description) do |journey_pattern|
  partial("api/v1/routes/short_description", :object => journey_pattern.route)
end
node(:vehicle_journey_object_ids) do |journey_pattern|
  journey_pattern.vehicle_journeys.pluck(:objectid)
end unless root_object.vehicle_journeys.empty?
child :stop_points => :stop_area_short_descriptions do |stop_points|
  attributes :position
  node do |stop_point|
    cache stop_point.id
    partial("api/v1/stop_areas/short_description", :object => stop_point.stop_area)
  end
end
child(:shape) do |shape|
  attributes :id, :uuid, :name
  node(:has_waypoints) { |shape| shape.waypoints.any? }
end