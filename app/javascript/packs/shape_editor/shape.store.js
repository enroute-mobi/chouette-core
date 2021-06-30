import Store from '../../helpers/store'
import { reducer, initialState } from './shape.reducer'

const mapDispatchToProps = dispatch => ({
  moveWaypoint: (id, coordinates) => ({ type: 'MOVE_WAYPOINT', id, coordinates }),
  setAttributes: payload => dispatch({ type: 'SET_ATTRIBUTES', payload }),
  setLine: line => dispatch({ type: 'SET_LINE', line }),
  setWaypoints: waypoints =>  dispatch({ type: 'SET_WAYPOINTS', waypoints }),
  addNewPoint: waypoint => dispatch({ type: 'ADD_WAYPOINT', waypoint })
})

export default new Store(reducer, initialState, mapDispatchToProps)