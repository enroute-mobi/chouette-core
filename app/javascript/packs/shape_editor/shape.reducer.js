import { Style } from 'ol/style'
import { chain, flow } from 'lodash'
import {
  nearestPointOnLine,
  lineString as turfLine,
  point as turfPoint,
  lineSlice,
  getCoords,
  length,
  simplify
} from '@turf/turf'

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
        turfLine: buildTurfLine(action.line)
      }
    case 'SET_WAYPOINTS':
      return {
        ...state,
        waypoints: action.waypoints
      }
    case 'ADD_WAYPOINT':
      return {
        ...state,
        waypoints: [...state.waypoints, action.waypoint]
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
  modify: null,
  shouldUpdateLine: false,
  style: new Style({})
}

export const convertCoords = feature =>
  feature
  .getGeometry()
  .clone()
  .transform('EPSG:3857', 'EPSG:4326')
  .getCoordinates()

export const buildTurfLine = line => turfLine(convertCoords(line))

export const simplifyGeoJSON = data => simplify(data, { tolerance: 0.0001, highQuality: true }) // We may want to have a dynamic tolerance

const getSortedWaypoints = state => {
  const { turfLine: line, waypoints } = state

  if (!line) return []

  const firstPoint = !!line && turfPoint(getCoords(line)[0])

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

const getSortedCoordinates = flow(
  getSortedWaypoints,
  waypoints => waypoints.map(convertCoords)
)

export const actions = {
  setAttributes: payload => ({ type: 'SET_ATTRIBUTES', payload }),
  setLine: line => ({ type: 'SET_LINE', line, turfLine }),
  setWaypoints: waypoints =>  ({ type: 'SET_WAYPOINTS', waypoints }),
  addNewPoint: waypoint => ({ type: 'ADD_WAYPOINT', waypoint })
}

export const selectors = {
  getSortedWaypoints,
  getSortedCoordinates
}

export const helpers = {
  buildTurfLine,
  convertCoords,
  simplifyGeoJSON
}