object @route

node(:type) { 'FeatureCollection' }

node(:crs) do
  {
    type: 'name',
    properties: {
      name: 'EPSG:3857',
    }
  }
end

node(:features) do |route|
   [
     {
      type: 'Feature',
      geometry: {
        type: 'LineString',
        coordinates: route.stop_areas.map { |s| [s.longitude, s.latitude] }
      },
      properties: {
        name: route.line.name
      }
    },
    *partial('stop_areas/index.geo', object: route.stop_areas)
  ]
end