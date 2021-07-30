object false

node(:type) { 'FeatureCollection' }

node(:crs) do
  {
    type: 'name',
    properties: {
      name: 'EPSG:3857',
    }
  }
end

node(:features) do
  line_string = {
    type: 'Feature',
    geometry: {
      type: 'LineString',
      coordinates: @shape.geometry.coordinates
    },
    properties: {
      name: @shape.name
    }
  }

  points = @shape.waypoints.map do |waypoint|
    {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: waypoint.coordinates
      },
      properties: {
        name: waypoint.name || '-',
        type: waypoint.waypoint_type
      }
    }
  end

  [
    line_string,
    *points
  ]
end