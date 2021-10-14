import statusReducer, { initialState } from '../../../../app/packs/src/routes/reducers/status'
import { actionHandler, receivedUserPermissions } from '../helpers'

const it_should_handle = actionHandler(statusReducer)(initialState)

describe('status reducer', () => {
  it('should return the initial state', () => {
    expect(
      statusReducer(undefined, {})
    ).toEqual(initialState)
  })

  it_should_handle(
    { type: 'FETCH_START' },
    Object.assign({}, initialState, { isFetching: true, fetchSuccess: false, fetchError: false })
  )

  it_should_handle(
    { type: 'FETCH_SUCCESS' },
    Object.assign({}, initialState, { isFetching: false, fetchSuccess: true, fetchError: false })
  )

  it_should_handle(
    { type: 'FETCH_ERROR' },
    Object.assign({}, initialState, { isFetching: false, fetchSuccess: false, fetchError: true })
  )

  it_should_handle(
    { type: 'RECEIVE_USER_PERMISSIONS', json: receivedUserPermissions },
    Object.assign({}, initialState, { policy: receivedUserPermissions })
  )
})