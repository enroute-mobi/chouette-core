import React from 'react'
import { render } from 'react-dom'
import { Path } from 'path-parser'
import { flatten, map } from 'lodash'
import geoJSON from '../../src/helpers/geoJSON'

import MapWrapper from '../../src/components/MapWrapper'
import { connectionLinkStyle } from '../../src/helpers/open_layers/styles'

const initMap = async () => {
  const path = new Path('/workbenches/:workbenchId/stop_area_referential/stop_areas/:id')
  const { workbenchId, id } = path.partialTest(location.pathname)

  const baseURL = path.build({ workbenchId, id })
  const stopAreaURL = `${baseURL}.geojson`
  const connectionLinksURL = `${baseURL}/fetch_connection_links.geojson`

  const features = await Promise.all([
    fetch(stopAreaURL),
    fetch(connectionLinksURL),
  ]).then(async ([res1, res2]) => {
    const stopArea = geoJSON.readFeature(await res1.json())
    const connectionLinksCollection = map(await res2.json(), cl => {
      const features = geoJSON.readFeatures(cl)

      features.forEach(f => f.setStyle(
        connectionLinkStyle(f.get('marker'))
      ))

      return features
    })

    return [stopArea, ...flatten(connectionLinksCollection)]
  })

  render(
    <div className='ol-map'>
      <MapWrapper features={features} />
    </div>,
    document.getElementById('connection_link_map')
  )
}

initMap()
