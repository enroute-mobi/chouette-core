import { chain, curryRight, flow, map } from 'lodash'
import {
  nearestPointOnLine,
  point,
  lineSlice,
  getCoords,
  length
} from '@turf/turf'

import { convertCoords } from './shape.helpers'

export const getSortedWaypoints = state => {
  const { turfLine: line, waypoints } = state

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

export const getSource = state => state.featuresLayer?.getSource()