export const initialState = {
  action: window.routeFormAction,
  editMode: true,
  policy: {},
  isFetching: false,
  fetchSuccess: false,
  fetchError: false,
  isSubmitting: false,
  submitSuccess: false,
  submitError: false
}

// Reducer
const status = (state = initialState, action) => {
  switch (action.type) {
    case 'FETCH_START':
      return Object.assign({}, state, { isFetching: true, fetchSuccess: false, fetchError: false })
    case 'RECEIVE_USER_PERMISSIONS':
      return Object.assign({}, state, {policy: action.json})
    case 'FETCH_SUCCESS':
      return Object.assign({}, state, { isFetching: false, fetchSuccess: true, fetchError: false })
    case 'FETCH_ERROR':
      return Object.assign({}, state, { isFetching: false, fetchSuccess: false, fetchError: true })
    default:
      return state
  }
}

// Helpers
export const isActionCreate = statusState => statusState.action === 'create'
export const getRequestMethod = statusState => isActionCreate(statusState) ? 'POST' : 'PATCH'

export default status