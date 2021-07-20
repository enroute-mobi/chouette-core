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
  permissions: {
    canCreate: false,
    canUpdate: false
  },
  name: '',
  features: [],
  map: null,
  line: null,
  waypoints: new Collection([]),
  draw: null,
  snap: null,
  modify: null,
  style: new Style({})
}