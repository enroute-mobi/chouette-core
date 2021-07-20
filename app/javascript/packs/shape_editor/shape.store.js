import Store from '../../helpers/Store'
import { reducer, initialState } from './shape.reducer'

const mapDispatchToProps = dispatch => ({
  setAttributes: payload => dispatch({ type: 'SET_ATTRIBUTES', payload })
})

export default new Store(reducer, initialState, mapDispatchToProps)