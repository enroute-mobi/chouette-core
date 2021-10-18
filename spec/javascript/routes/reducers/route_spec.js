import routeReducer, { initialState } from '../../../../app/packs/src/routes/reducers/route'
import { actionHandler, receivedRoute } from '../helpers'
import _ from 'lodash'

const it_should_handle = actionHandler(routeReducer)(initialState)

describe('route reducer', () => {
  it('should return the initial state', () => {
    expect(
      routeReducer(undefined, {})
    ).toEqual(initialState)
  })

  Array.of('name', 'published_name', 'wayback', 'opposite_route_id').forEach(attribute => {
    const obj = { [attribute]: attribute }
    it_should_handle(
      { type: "UPDATE_ROUTE_FORM_INPUT", attributes: obj },
      _.assign(initialState, obj),
    )
  })

  it_should_handle(
    { type: "RECEIVE_ROUTE", json: receivedRoute },
    _.omit(receivedRoute, ['stop_points']),
  )
})