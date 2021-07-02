import { simplify } from '@turf/turf'
import { dropRight } from 'lodash'
import Modify from 'ol/interaction/Modify'
import Draw from 'ol/interaction/Draw'
import Snap from 'ol/interaction/Snap'

import store from './shape.store'
import { getMapInteractions } from './shape.selectors'

export const convertCoords = feature =>
  feature
  .getGeometry()
  .clone()
  .transform('EPSG:3857', 'EPSG:4326')
  .getCoordinates()

export const getLine = features => features.find(f => f.getGeometry().getType() == 'LineString')
export const getLineSegments = feature => {
  const segments = []

  feature.getGeometry().forEachSegment((start, end) => {
    segments.push({ start, end })
  })

  return segments
}

export const getWaypoints = features => features.filter(f => f.getGeometry().getType() == 'Point')

export const simplifyGeoJSON = data => simplify(data, { tolerance: 0.0001, highQuality: true }) // We may want to have a dynamic tolerance

export const addMapInteractions = (source, map, waypoints) => {
  const modify = new Modify({ features: waypoints })
  const draw = new Draw({ source, features: waypoints, type: 'Point' })
  const snap = new Snap({ source })
  const interactions = [modify, draw, snap]

  interactions.forEach(i => map.addInteraction(i))
  store.setAttributes({ draw, modify, snap })
}

export const lineId = 'line'
export const baseURL = (() => {
  const parts = window.location.pathname.split('/')
  return dropRight(parts).join('/')
})()

export const wktOptions = { //  use options to convert feature from EPSG:4326 to EPSG:3857
  dataProjection: 'EPSG:4326',
  featureProjection: 'EPSG:3857'
}