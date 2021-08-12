const oppositeRoutes = (state = {}, action) => {
  switch(action.type) {
    case 'RECEIVE_OPPOSITE_ROUTES':
      return action.json
    default:
      return state
  }
}

export default oppositeRoutes