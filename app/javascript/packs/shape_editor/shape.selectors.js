import { filter, find, flow, map, partialRight, reduce } from 'lodash'
import { lineSlice, lineString } from '@turf/turf'

import { getFeatureCoordinates, isLine, isWaypoint } from './shape.helpers'

const getShapeFeatures = state => state.shapeFeatures

const shapeFeaturesToArray = shapeFeatures => shapeFeatures?.getArray() || []

export const getLine = flow(getShapeFeatures, shapeFeaturesToArray, partialRight(find, isLine))
export const getWaypoints = flow(getShapeFeatures, shapeFeaturesToArray, partialRight(filter, isWaypoint))

export const getLineCoords = flow(getLine, getFeatureCoordinates)
export const getWaypointsCoords = flow(getWaypoints, partialRight(map, getFeatureCoordinates))

export const getLineSections = state => {
  const line = flow(getLineCoords, lineString)(state)

  return reduce(
    getWaypointsCoords(state),
    (result, coords, index, collection) => {
      const nextCoords = collection[index + 1]

      if (!nextCoords) return result

      return [
        ...result,
        lineSlice(coords, nextCoords, line)
      ]
    },
    []
  )
}

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
    coordinates: getLineCoords(state),
    waypoints: map(getWaypoints(state), (w, position) => ({
      name: w.get('name'),
      position,
      waypoint_type: w.get('type'),
      coordinates: getFeatureCoordinates(w)
    }))
  }
})
