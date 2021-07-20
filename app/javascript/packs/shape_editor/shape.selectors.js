import { chain, curryRight, flow, map } from 'lodash'
import {
  nearestPointOnLine,
  point,
  lineSlice,
  lineString,
  getCoords,
  length
} from '@turf/turf'

import { convertCoords } from './shape.helpers'

export const getTurfLine = ({ line }) => line ?  lineString(convertCoords(line)) : null

export const getSortedWaypoints = state => {
  const { waypoints } = state
  const line = getTurfLine(state)

  if (!line) return []

  const firstPoint = !!line && point(getCoords(line)[0])

  return chain(waypoints.getArray())
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

export const getSubmitPayload = ({ name, waypoints, line }) => ({
  shape: {
    name,
    coordinates: line.getGeometry().getCoordinates(),
    waypoints: waypoints.getArray().map((w, position) => ({
      name: w.get('name'),
      position,
      waypoint_type: w.get('type'),
      coordinates: w.getGeometry().getCoordinates()
    }))
  }
})