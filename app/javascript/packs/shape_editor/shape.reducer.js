import { Circle, Fill, Stroke, Style } from 'ol/style'
import { chain, flow, uniqueId } from 'lodash'
import {
  nearestPointOnLine,
  lineString as turfLine,
  point as turfPoint,
  lineSlice,
  getCoords,
  length
} from '@turf/turf'

const lineId = 'line'

const constraintStyle = new Style({
  image: new Circle({
    radius: 2.5,
    stroke: new Stroke({ color: 'black', width: 1 }),
    fill: new Fill({ color: 'rgba(255, 255, 255, 0.5)' })
   })
})

export const reducer = (state, action) => {
  switch(action.type) {
    case 'SET_ATTRIBUTES':
      return {
        ...state,
        ...action.payload
      }
    case 'SET_LINE':
      action.line.setId(lineId)
  
      return {
        ...state,
        line: action.line,
        turfLine: turfLine(convertCoords(action.line)),
        waypoints: state.waypoints
      }
    case 'SET_WAYPOINTS':
      action.waypoints.forEach(w => {
        w.setId(uniqueId('waypoint_'))
        w.set('type', 'waypoint')
      })
  
      return {
        ...state,
        waypoints: action.waypoints
      }
    case 'ADD_WAYPOINT':
      action.waypoint.set('type', 'constraint')
      action.waypoint.setStyle(constraintStyle)
  
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
  style: new Style({})
}

export const actions = {
  setAttributes: payload => ({ type: 'SET_ATTRIBUTES', payload }),
  setLine: line => ({ type: 'SET_LINE', line }),
  setWaypoints: waypoints =>  ({ type: 'SET_WAYPOINTS', waypoints }),
  addNewPoint: waypoint => ({ type: 'ADD_WAYPOINT', waypoint }),
  updateLine: coordinates => ({ type: 'UPDATE_LINE', coordinates })
}

export const convertCoords = feature =>
  feature
  .getGeometry()
  .clone()
  .transform('EPSG:3857', 'EPSG:4326')
  .getCoordinates()

const getSortedWaypoints = state => {
  const { turfLine: line, waypoints } = state

  if (!line) return []

  const firstPoint = !!line && turfPoint(getCoords(line)[0])

  return chain(waypoints)
    .map(w => {
      // const point = nearestPointOnLine(convertCoords(w), line)
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

export const selectors = {
  getSortedWaypoints,
  getSortedCoordinates
}