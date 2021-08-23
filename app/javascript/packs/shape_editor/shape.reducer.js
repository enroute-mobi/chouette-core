import { Style } from 'ol/style'
import Collection from 'ol/Collection'

export const reducer = (state, action) => {
  switch(action.type) {
    case 'SET_ATTRIBUTES':
      return {
        ...state,
        ...action.payload
      }
    default:
      return state
  }
}

export const initialState = {
  line: null,
  map: null,
  modify: null,
  permissions: {
    canCreate: false,
    canUpdate: false
  },
  routeFeatures: null,
  snap: null,
  style: new Style({}),
  waypoints: new Collection([]),
}
