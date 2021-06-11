import { Style } from 'ol/style'
import { chain, uniqueId } from 'lodash'
import {
  nearestPointOnLine,
  lineString as turfLine,
  point as turfPoint,
  lineSlice,
  getCoords,
  length
} from '@turf/turf'

const fromOLToTurfCoords = feature =>
  feature
  .getGeometry()
  .clone()
  .transform('EPSG:3857', 'EPSG:4326')
  .getCoordinates()

const getSortedWaypoints = (line, waypoints) =>
  chain(waypoints)
  .map(w => {
    // Creaye a line slice from the beginning to the current point to determine the length of this "subLine"
    const subLine = lineSlice(
      turfPoint(getCoords(line)[0]),
      turfPoint(fromOLToTurfCoords(w)),
      line
    )

    w.setId(uniqueId('waypoint_'))
    w.set('distanceFromStart', length(subLine))

    return w
  })
  .sortBy(w => w.getProperties().distanceFromStart)
  .value()

export const reducer = (state, action) => {
  switch(action.type) {
    case 'SET_ATTRIBUTES':
      return {
        ...state,
        ...action.payload
      }
    case 'SET_LINE':
      return {
        ...state,
        line: action.line,
        turfLine: turfLine(fromOLToTurfCoords(action.line))
      }
    case 'SET_WAYPOINTS':
      return {
        ...state,
        waypoints: getSortedWaypoints(state.turfLine, action.waypoints)
      }
    default:
      return state
  }
}

export const initialState = {
  features: [],
  map: null,
  featuresLayer: null,
  line: null,
  waypoints: [],
  draw: null,
  snap: null,
  style: new Style({})
}

export const actions = {
  setAttributes: payload => ({ type: 'SET_ATTRIBUTES', payload }),
  setLine: line => ({ type: 'SET_LINE', line }),
  setWaypoints: waypoints =>  ({ type: 'SET_WAYPOINTS', waypoints }),
  addNewPoint: point => ({ type: 'ADD_POINT'})
}