%i[
  id
  name
  published_name
  registration_number
  comment
  checksum
  custom_fields
  shape_id
  object_version
  created_at
  updated_at
].each do |attr|
  attributes attr, unless: ->(m) { m.send(attr).nil? }
end

attribute :costs

node do |model|
  { short_id: model.get_objectid.short_id }
end

node :full_schedule do |journey_pattern|
  journey_pattern.full_schedule?
end

child route: :route_short_description do |route|
  %i[
    name
    published_name
    number
    direction
    wayback
  ].each do |attr|
    attributes attr, unless: ->(m) { m.send(attr).nil? }
  end

  attributes objectid: :object_id
  attributes :object_version

  child :stop_points, object_root: false do |stop_points|
    node do |stop_point|
      partial('journey_patterns_collections/stop_area_short_description', object: stop_point.stop_area)
    end

    attribute :position
  end
end

node do |journey_pattern|
  unless journey_pattern.vehicle_journeys.empty?
    node :vehicle_journey_object_ids do |journey_pattern|
      journey_pattern.vehicle_journeys.pluck(:objectid)
    end
  end
end

child stop_points: :stop_area_short_descriptions do |stop_points|
  attributes :position
  node do |stop_point|
    cache stop_point.id
    partial('journey_patterns_collections/stop_area_short_description', object: stop_point.stop_area)
  end
end

child :shape do |shape|
  attributes :id, :uuid, :name
  node :has_waypoints do |shape|
    shape.waypoints.any?
  end
end
