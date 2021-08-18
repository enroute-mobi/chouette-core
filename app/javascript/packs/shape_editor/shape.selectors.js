import { curryRight, flow, map, sortBy } from 'lodash'
import { lineString } from '@turf/turf'

import { convertCoords, isLine, isWaypoint } from './shape.helpers'

export const getLine = ({ shapeFeatures }) => shapeFeatures.getArray().find(isLine)
export const getWaypoints = ({ shapeFeatures }) => shapeFeatures.getArray().filter(isWaypoint)

export const getTurfLine = flow(
  getLine,
  line => line ? lineString(convertCoords(line)) : null
)

export const getSortedWaypoints = state => sortBy(
  getWaypoints(state),
  w => w.get('distanceFromStart')
)

export const getSortedCoordinates = flow(
  getSortedWaypoints,
  curryRight(map)(convertCoords)
)

export const getLayers = state => state.map?.getLayers()

const getLayer = type => flow(
  getLayers,
  layers => layers?.getArray()?.find(layer => layer.get('type') == type)
)

const getSource = type => flow(
  getLayer(type),
  layer => layer?.getSource()
)

export const getInteractiveLayer = getLayer('interactive')

export const getStaticlayer = getLayer('static')

export const getInteractiveSource = getSource('interactive')

export const getStaticSource = getSource('static')

export const getSubmitPayload = state => ({
  shape: {
    name: state.name,
    coordinates: convertCoords(getLine(state)),
    waypoints: getSortedWaypoints(state).map((w, position) => ({
      name: w.get('name'),
      position,
      waypoint_type: w.get('type'),
      coordinates: convertCoords(w)
    }))
  }
})
