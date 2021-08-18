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
  routeFeatures: new Collection([]),
  shapeFeatures: new Collection([]),
  mapWrapperFeatures: [], // Only used or the MapWrapper compnent (should be only update once, when we fetch the features onMount)
  map: null,
  line: null,
  waypoints: new Collection([], { unique: true }),
  draw: null,
  snap: null,
  modify: null,
  style: new Style({})
}
