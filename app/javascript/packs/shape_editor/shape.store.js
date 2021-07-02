import Store from '../../helpers/Store'
import { reducer, initialState } from './shape.reducer'

const mapDispatchToProps = dispatch => ({
  setAttributes: payload => dispatch({ type: 'SET_ATTRIBUTES', payload }),
  setLine: line => dispatch({ type: 'SET_LINE', line }),
  setWaypoints: waypoints =>  dispatch({ type: 'SET_WAYPOINTS', waypoints })
})

export default new Store(reducer, initialState, mapDispatchToProps)