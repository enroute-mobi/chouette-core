import assign from 'lodash/assign'
import filter from 'lodash/filter'
import actions from '../actions'

export default function metas(state = {}, action) {
  switch (action.type) {
    case 'RECEIVE_TIME_TABLES':
      return assign({}, state, {
        comment: action.json.comment,
        day_types: actions.strToArrayDayTypes(action.json.day_types),
        tags: action.json.tags,
        initial_tags: action.json.tags,
        color: action.json.color,
        calendar: action.json.calendar ? action.json.calendar : null
      })
    case 'RECEIVE_MONTH':
      let dt = (typeof state.day_types === 'string') ? actions.strToArrayDayTypes(state.day_types) : state.day_types
      return assign({}, state, {day_types: dt})
    case 'ADD_INCLUDED_DATE':
    case 'REMOVE_INCLUDED_DATE':
    case 'ADD_EXCLUDED_DATE':
    case 'REMOVE_EXCLUDED_DATE':
    case 'DELETE_PERIOD':
    case 'VALIDATE_PERIOD_FORM':
      return assign({}, state, {calendar: null})
    case 'UPDATE_DAY_TYPES':
      return assign({}, state, {day_types: action.dayTypes, calendar : null})
    case 'UPDATE_COMMENT':
      return assign({}, state, {comment: action.comment})
    case 'UPDATE_COLOR':
      return assign({}, state, {color: action.color})
    case 'SET_NEW_TAGS':
      return assign({}, state, { tags: action.tagList })
    default:
      return state
  }
}
