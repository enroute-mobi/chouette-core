const mapDispatchToProps = dispatch => ({
  setAttributes: payload => dispatch({ type: 'SET_ATTRIBUTES', payload }),
  setLine: line => dispatch({ type: 'SET_LINE', line }),
  setWaypoints: waypoints =>  dispatch({ type: 'SET_WAYPOINTS', waypoints }),
  addNewPoint: waypoint => dispatch({ type: 'ADD_WAYPOINT', waypoint })
})

export default mapDispatchToProps