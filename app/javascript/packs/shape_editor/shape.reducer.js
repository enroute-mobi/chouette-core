import { Style } from 'ol/style'

import { buildTurfLine } from './shape.helpers'

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