import { chain, curryRight, flow, get, map } from 'lodash'
import {
  nearestPointOnLine,
  point,
  lineSlice,
  lineString,
  getCoords,
  length
} from '@turf/turf'

import { convertCoords, isLine, isWaypoint } from './shape.helpers'

export const getLine = ({ shapeFeatures }) => shapeFeatures.getArray().find(isLine)
export const getWaypoints = ({ shapeFeatures }) => shapeFeatures.getArray().filter(isWaypoint)

export const getTurfLine = flow(
  getLine,
  line => line ? lineString(convertCoords(line)) : null
)

export const getSortedWaypoints = state => {
  const line = getTurfLine(state)
  const waypoints = getWaypoints(state)

  if (!line) return []

  const firstPoint = !!line && point(getCoords(line)[0])

  return chain(waypoints)
  .map(w => {
    // Create a line slice from the beginning to the current point to determine the length of this "subLine"
      const subLine = lineSlice(
        firstPoint,
        nearestPointOnLine(line, convertCoords(w)),
        line
      )

      w.set('distanceFromStart', length(subLine))

      return w
    })
    .sortBy(w => w.getProperties().distanceFromStart)
    .value()
}

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
    coordinates: getLine(state).getGeometry().getCoordinates(),
    waypoints: getWaypoints(state).map((w, position) => ({
      name: w.get('name'),
      position,
      waypoint_type: w.get('type'),
      coordinates: w.getGeometry().getCoordinates()
    }))
  }
})