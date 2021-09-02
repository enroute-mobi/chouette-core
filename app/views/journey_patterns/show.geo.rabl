object @journey_pattern

node(:type) { 'FeatureCollection' }

extends 'geojson/crs'

node(:features) do |jp|
  line_string = TomTom::BuildLineStringFeature.call(
    jp.stop_areas.map { |s| [s.longitude, s.latitude] },
    @journey_pattern.route.name
  )

  [
    line_string,
    *partial('stop_areas/index.geo', object: @journey_pattern.stop_areas)
  ]
end
