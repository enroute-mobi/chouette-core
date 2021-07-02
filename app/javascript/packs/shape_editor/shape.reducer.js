import { Style } from 'ol/style'
import Collection from 'ol/Collection'

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
        line: action.line
      }
    case 'SET_WAYPOINTS':
      return {
        ...state,
        waypoints: action.waypoints
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
  waypoints: new Collection([]),
  draw: null,
  snap: null,
  modify: null,
  style: new Style({})
}