import omit from 'lodash/omit'

// Constants
const UPDATE_ROUTE_FORM_INPUT = 'UPDATE_ROUTE_FORM_INPUT'
export const RECEIVE_ROUTE = 'RECEIVE_ROUTE'

export const SUBMIT_ROUTE_START = 'SUBMIT_ROUTE_START'
export const SUBMIT_ROUTE_SUCCESS = 'SUBMIT_ROUTE_SUCCESS'
export const SUBMIT_ROUTE_ERROR = 'SUBMIT_ROUTE_ERROR'

export const initialState = {
  name: '',
  published_name: '',
  wayback: 'outbound',
  opposite_route_id: null,
  line_id: parseInt(window.location.pathname.split('/')[4])
}

// Reducer
const route = (state = initialState, action) => {
  switch(action.type) {
    case UPDATE_ROUTE_FORM_INPUT:
      return Object.assign({}, state, action.attributes)
    case RECEIVE_ROUTE:
      return omit(action.json, ['stop_points'])
    default:
    return state
  }
}

// Helpers
export const handleInputChange = attribute => value => () => ({
  [attribute]: value
})

export const getWayback = e => e.target.checked ? 'outbound' : 'inbound'

export const getStopPointsAttributes = state => {
  const stopPoints = state.stopPoints.map((sp, index) => {
    return {
      id: sp.stoppoint_id || '',
      stop_area_id: sp.stoparea_id,
      position: index,
      for_boarding: sp.for_boarding,
      for_alighting: sp.for_alighting,
      _destroy: sp._destroy
    }
  })

  return stopPoints.concat(state.deletedStopPoints)
}

export default route
