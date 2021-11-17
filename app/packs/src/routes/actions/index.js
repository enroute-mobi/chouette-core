import { getRedirectUrl } from '../reducers/status'

const actions = {
  addStop : () => {
    return {
      type: 'ADD_STOP'
    }
  },
  moveStopUp : (index) => {
    return {
      type: 'MOVE_STOP_UP',
      index
    }
  },
  moveStopDown : (index) => {
    return {
      type: 'MOVE_STOP_DOWN',
      index
    }
  },
  deleteStop : (index, stopPointId) => {
    return {
      type: 'DELETE_STOP',
      index,
      stopPointId
    }
  },
  updateInputValue : (index, text) => {
    return {
      type : 'UPDATE_INPUT_VALUE',
      index,
      text
    }
  },
  updateSelectValue: (e, index) => {
    return {
      type :'UPDATE_SELECT_VALUE',
      select_id: e.currentTarget.id,
      select_value: e.currentTarget.value,
      index
    }
  },
  toggleMap: (index) =>({
    type: 'TOGGLE_MAP',
    index
  }),
  toggleEdit: (index) =>({
    type: 'TOGGLE_EDIT',
    index
  }),
  closeMaps: () => ({
    type : 'CLOSE_MAP'
  }),
  selectMarker: (index, data) =>({
    type: 'SELECT_MARKER',
    index,
    data
  }),
  unselectMarker: (index) => ({
    type: 'UNSELECT_MARKER',
    index
  }),
  updateRouteFormInput: attributes => ({
    type: 'UPDATE_ROUTE_FORM_INPUT',
    attributes
  }),
  fetchWrapper: dispatch => fetchUrl => async resourceName => {
    const response = await fetch(fetchUrl)
    if (!response.ok) {
      const { status, statusText: message } = response
      throw { status, message }
    }
    const json = await response.json()
    dispatch({ type: `RECEIVE_${resourceName}`, json })
  },
  fetchResources: dispatch => mustFetchRoute => async () => {
    dispatch({ type: 'FETCH_START' })

    return Promise.all([
      actions.fetchUserPermissions(dispatch),
      actions.fetchOppositeRoutes(dispatch),
      ...(mustFetchRoute ? [actions.fetchRoute(dispatch)] : [])
    ])
    .then(() => dispatch({ type: 'FETCH_SUCCESS' }))
    .catch(error => dispatch({ type: 'FETCH_ERROR', error }))
  },
  fetchUserPermissions: dispatch => actions.fetchWrapper(dispatch)(window.fetchUserPermissionsUrl)('USER_PERMISSIONS'),
  fetchOppositeRoutes: dispatch => actions.fetchWrapper(dispatch)(window.fetchOppositeRoutesUrl)('OPPOSITE_ROUTES'),
  fetchRoute: dispatch => actions.fetchWrapper(dispatch)(window.fetchRouteUrl)('ROUTE'),
  validateField: ({category, ...value}) => ({
    type: 'VALIDATE_FIELD',
    category,
    value
  }),
  submitRoute: dispatch => requestMethod => async route => {
    try {
      dispatch({ type: 'SUBMIT_ROUTE_START' })
      const response = await fetch(window.routeSubmitUrl, {
        credentials: 'same-origin',
        method: requestMethod,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json;  charset=utf-8',
          'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
          },
        body: JSON.stringify({route: route})
        }
      )
      const json = await response.json()
      dispatch({ type: 'SUBMIT_ROUTE_SUCCESS', json })
      window.location.assign(window.redirectUrl)
    } catch(error) {
      dispatch({ type: 'SUBMIT_ROUTE_ERROR', error })
    }
  }
}

export default actions
