import { simplify } from '@turf/turf'

import Collection from 'ol/Collection'
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
export const getWaypoints = features => features.filter(f => f.getGeometry().getType() == 'Point')

export const simplifyGeoJSON = data => simplify(data, { tolerance: 0.0001, highQuality: true }) // We may want to have a dynamic tolerance

export const addMapInteractions = (source, state) => {
  const interactions = getMapInteractions(state)
  interactions.forEach(i => state.map.removeInteraction(i))

  const modify = new Modify({ features: new Collection(state.waypoints) })
  const draw = new Draw({ source, type: 'Point' })
  const snap = new Snap({ source })
  const newInteractions = [modify, draw, snap]

  newInteractions.forEach(i => state.map.addInteraction(i))
  store.setAttributes({ draw, modify, snap })
}

export const lineId = 'line'
export const baseURL = window.location.pathname.split('/shape_editor')[0]

export const wktOptions = { //  use options to convert feature from EPSG:4326 to EPSG:3857
    dataProjection: 'EPSG:4326',
    featureProjection: 'EPSG:3857'
  }