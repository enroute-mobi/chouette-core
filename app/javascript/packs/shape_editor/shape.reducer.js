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
    case 'MOVE_WAYPOINT':
      return {
        ...state,
        waypoints: state.waypoints.reduce((result, w) => {
          w.getId() == action.id && w.setCoordinates(action.coordinates)
          return result.concat(w)
        }, [])
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
  style: new Style({}),
  baseURL: window.location.pathname.split('/shape_editor')[0],
  lineId: 'line',
  wktOptions: { //  use options to convert feature from EPSG:4326 to EPSG:3857
    dataProjection: 'EPSG:4326',
    featureProjection: 'EPSG:3857'
  }
}