import omit from 'lodash/omit'

// Constants
const UPDATE_ROUTE_FORM_INPUT = 'UPDATE_ROUTE_FORM_INPUT'
export const RECEIVE_ROUTE = 'RECEIVE_ROUTE'

export const SUBMIT_ROUTE_START = 'SUBMIT_ROUTE_START'
export const SUBMIT_ROUTE_SUCCESS = 'SUBMIT_ROUTE_SUCCESS'
export const SUBMIT_ROUTE_ERROR = 'SUBMIT_ROUTE_ERROR'
export const ADD_CODE = 'ADD_CODE'
export const UPDATE_CODE = 'UPDATE_CODE'
export const DELETE_CODE = 'DELETE_CODE'

export const initialState = {
  name: '',
  published_name: '',
  wayback: 'outbound',
  opposite_route_id: null,
  line_id: parseInt(window.location.pathname.split('/')[4]),
  code_values: []
}

// Reducer
const route = (state = initialState, action) => {
  let newCodeValues
  switch(action.type) {
    case UPDATE_ROUTE_FORM_INPUT:
      return Object.assign({}, state, action.attributes)
    case RECEIVE_ROUTE:
      return {
        ...omit(action.json, ['stop_points']),
        code_values: action.json.code_values || []
      }
    case ADD_CODE:
      newCodeValues = [...(state.code_values || []), action.code]
      return { ...state, code_values: newCodeValues }
    case UPDATE_CODE:
      newCodeValues = [...(state.code_values || [])]
      const updatedCode = {
        ...newCodeValues[action.attributes.index],
        code_space_id: action.attributes.code_space_id,
        value: action.attributes.value
      }
      newCodeValues[action.attributes.index] = updatedCode
      return { ...state, code_values: newCodeValues }
    case DELETE_CODE:
      newCodeValues = [...(state.code_values || [])]
      newCodeValues[action.index] = {
        ...newCodeValues[action.index],
        _destroy: true
      }
      return { ...state, code_values: newCodeValues }
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
      flexible: sp.flexible,
      _destroy: sp._destroy
    }
  })

  return stopPoints.concat(state.deletedStopPoints)
}

export default route
