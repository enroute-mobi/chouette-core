import assign from 'lodash/assign'

export default function status(state = {}, action) {
  switch (action.type) {
    case 'UNAVAILABLE_SERVER':
      return assign({}, state, {fetchSuccess: false})
    case 'FETCH_API':
      return assign({}, state, {isFetching: true})
    case 'RECEIVE_TIME_TABLES':
    case 'RECEIVE_MONTH':
      return assign({}, state, {fetchSuccess: true, isFetching: false})
    default:
      return state
  }
}