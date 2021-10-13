import { Style } from 'ol/style'
import Collection from 'ol/Collection'

import { INIT_MAP, RECEIVE_PERMISSIONS, RECEIVE_ROUTE_FEATURES, RECEIVE_SHAPE_FEATURES, SET_ATTRIBUTES, UPDATE_GEOMETRY, UPDATE_NAME, UPDATE_WAYPOINTS } from './shape.actions'

export const reducer = (state, action) => {
  switch(action.type) {
    case INIT_MAP:
    case RECEIVE_PERMISSIONS:
    case RECEIVE_ROUTE_FEATURES:
    case RECEIVE_SHAPE_FEATURES:
    case SET_ATTRIBUTES:
    case UPDATE_GEOMETRY:
    case UPDATE_NAME:
    case UPDATE_WAYPOINTS:
      return {
        ...state,
        ...action.payload
      }
    default:
      return state
  }
}

export const initialState = {
  line: new Collection([]),
  map: null,
  modify: null,
  permissions: {
    canCreate: false,
    canUpdate: false
  },
  name: '',
  routeFeatures: null,
  style: new Style({}),
  waypoints: new Collection([]),
}
