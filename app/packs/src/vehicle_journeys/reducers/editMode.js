export default function editMode(state = {}, action ) {
  switch (action.type) {
    case "ENTER_EDIT_MODE":
      return true
    case "EXIT_EDIT_MODE":
      return false
    default:
      return state
  }
}