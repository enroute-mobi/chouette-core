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

export const getMapInteractions = ({ draw, modify, snap }) => ([ draw, modify, snap ])