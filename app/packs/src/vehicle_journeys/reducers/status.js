import _ from 'lodash'
import actions from '../actions'

export default function status(state = {}, action) {
  switch (action.type) {
    case 'UNAVAILABLE_SERVER':
      return _.assign({}, state, {fetchSuccess: false})
    case 'FETCH_API':
      return _.assign({}, state, {isFetching: true})
    case 'RECEIVE_VEHICLE_JOURNEYS':
      return _.assign({}, state, {fetchSuccess: true, isFetching: false})
    case 'RECEIVE_ERRORS':
      return _.assign({}, state, {fetchSuccess: true, isFetching: false})
    default:
      return state
  }
}