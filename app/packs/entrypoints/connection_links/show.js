import React from 'react'
import { render } from 'react-dom'
import { Path } from 'path-parser'
import geoJSON from '../../src/helpers/geoJSON'

import MapWrapper from '../../src/components/MapWrapper'

import { connectionLinkStyle } from '../../src/helpers/open_layers/styles'
  
const initMap = async () => {
  const path = new Path('/workbenches/:workbenchId/stop_area_referential/connection_links/:id')
  const { workbenchId, id } = path.partialTest(location.pathname)

  const res = await fetch(`${path.build({ workbenchId, id })}.geojson`)
  const features = geoJSON.readFeatures(await res.json())

  features.forEach(f => f.setStyle(
    connectionLinkStyle(f.get('marker'))
  ))

  render(
    <div className='ol-map'>
      <MapWrapper features={features} />
    </div>,
    document.getElementById('connection_link_map')
  )
}

initMap()
