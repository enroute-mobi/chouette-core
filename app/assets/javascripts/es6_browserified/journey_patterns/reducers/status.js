var _ = require('lodash')
var actions = require("../actions")

const status = (state = {}, action) => {
  switch (action.type) {
    case 'UNAVAILABLE_SERVER':
      return _.assign({}, state, {fetchSuccess: false})
    case 'FETCH_API':
      return _.assign({}, state, {isFetching: true})
    case 'RECEIVE_JOURNEY_PATTERNS':
      return _.assign({}, state, {fetchSuccess: true, isFetching: false})
    case 'RECEIVE_ERRORS':
      return _.assign({}, state, {isFetching: false})
    case 'ENTER_EDIT_MODE':
      return _.assign({}, state, {editMode: true})
    case 'EXIT_EDIT_MODE':
      return _.assign({}, state, {editMode: false})
    default:
      return state
  }
}

module.exports = status
