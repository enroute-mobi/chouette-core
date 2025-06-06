object @stop_area

node do |s|
  {
    type: 'Feature',
    geometry: {
      type: 'Point',
      coordinates: [s.longitude.to_s, s.latitude.to_s]
    },
    properties: {
      name: s.name,
      type: 'waypoint'
    }
  }
end
