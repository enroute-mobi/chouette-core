object @journey_pattern

node(:type) { 'FeatureCollection' }

extends 'geojson/crs'

node(:features) do |jp|
  line_string = TomTom::BuildLineStringFeature.call(
    jp.stop_points.map { |sp| [sp.stop_area.longitude, sp.stop_area.latitude] },
    @journey_pattern.route.name
  )

  points = jp.stop_points.map do |sp|
    partial('stop_areas/show.geo', object: sp.stop_area)
  end

  [
    line_string,
    *points
  ]
end
