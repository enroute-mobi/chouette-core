object @journey_pattern

node(:type) { 'FeatureCollection' }

node(:crs) do
  {
    type: 'name',
    properties: {
      name: 'EPSG:3857',
    }
  }
end

node(:features) do |jp|
  get_coords = ->(sp) do
    [
      sp.stop_area.longitude.round(5),
      sp.stop_area.latitude.round(5)
    ]
  end

  line_string = TomTom::BuildLineStringFeature.call(
    jp.stop_points.map(&get_coords)
  )

  points = jp.stop_points.map do |sp|
    {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: get_coords.call(sp).map(&:to_f)
      },
      properties: {
        name: sp.name
      }
    }
  end

  [
    line_string,
    *points
  ]
end