const deletedStopPoints = (state = [], action, length) => {
  switch (action.type) {
    case 'DELETE_STOP':
      const deletedStopPoint = { id: action.stopPointId, _destroy: true }

      //stopPoint is not persited don't need to track it
      if (!action.stopPointId) return state

      if (state.find(sp => action.stopPointId === sp.id)) return state

      return state.concat(deletedStopPoint)
    default:
      return state
  }
}

export default deletedStopPoints