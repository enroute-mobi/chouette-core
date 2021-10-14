import oppositeRoutesReducer from '../../../../app/packs/src/routes/reducers/oppositeRoutes'
import { actionHandler, receivedOppositeRoutes, state } from '../helpers'
import _ from 'lodash'

const it_should_handle = actionHandler(oppositeRoutesReducer)(state)

describe('oppositeRoutes reducer', () => {
  it('should return the initial state', () => {
    expect(
      oppositeRoutesReducer(undefined, {})
    ).toEqual({})
  })

  it_should_handle(
    { type: "RECEIVE_OPPOSITE_ROUTES", json: receivedOppositeRoutes },
    receivedOppositeRoutes
  )
})