object @connection_link

node(:type) { 'FeatureCollection' }

node(:crs) do
  {
    type: 'name',
    properties: {
      name: 'EPSG:3857',
    }
  }
end

node(:features) do |cl|
  departure, arrival = partial('stop_areas/index.geo', object: [cl.departure, cl.arrival])

	departure[:properties].merge!(
    marker: 'blue',
    type: 'connection_link'
  )
	arrival[:properties].merge!(
    marker: 'orange',
    type: 'connection_link'
  )

	[departure, arrival]
end
