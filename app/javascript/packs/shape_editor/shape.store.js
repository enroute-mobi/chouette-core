import Store from '../../helpers/store'
import { reducer, initialState } from './shape.reducer'
import mapDispatchToProps from './shape.actions'

export default new Store(reducer, initialState, mapDispatchToProps)