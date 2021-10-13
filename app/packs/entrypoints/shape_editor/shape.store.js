import Store from '../../helpers/Store'
import { actions } from './shape.actions'
import { reducer, initialState } from './shape.reducer'

export default new Store(reducer, initialState, actions)
