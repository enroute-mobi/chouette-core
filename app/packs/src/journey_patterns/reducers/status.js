export default function status (state = {}, action) {
  switch (action.type) {
    case 'UNAVAILABLE_SERVER':
      return { ...state, fetchSuccess: false }
    case 'FETCH_API':
      return { ...state, isFetching: true }
    case 'DUPLICATE_JOURNEY_PATTERN':
      return { ...state, isFetching: true }
    case 'RECEIVE_JOURNEY_PATTERNS':
      return { ...state, fetchSuccess: true, isFetching: false }
    case 'RECEIVE_ERRORS':
      return { ...state, isFetching: false }
    case 'ENTER_EDIT_MODE':
      return { ...state, editMode: true }
    case 'EXIT_EDIT_MODE':
      return { ...state, editMode: false }
    default:
      return state
  }
}