import statusReducer from '../../../../app/packs/src/time_tables/reducers/status'

let state = {}

describe('status reducer', () => {
  beforeEach(() => {
    state = {
      actionType: "edit",
      fetchSuccess: true,
      isFetching: false
    }
  })

  it('should return the initial state', () => {
    expect(
      statusReducer(undefined, {})
    ).toEqual({})
  })

  it('should handle UNAVAILABLE_SERVER', () => {
    expect(
      statusReducer(state, {
        type: 'UNAVAILABLE_SERVER'
      })
    ).toEqual(Object.assign({}, state, {fetchSuccess: false}))
  })

  it('should handle FETCH_API', () => {
    expect(
      statusReducer(state, {
        type: 'FETCH_API'
      })
    ).toEqual(Object.assign({}, state, {isFetching: true}))
  })

  it('should handle RECEIVE_TIME_TABLES', () => {
    expect(
      statusReducer(state, {
        type: 'RECEIVE_TIME_TABLES'
      })
    ).toEqual(Object.assign({}, state, {fetchSuccess: true, isFetching: false}))
  })
  it('should handle RECEIVE_MONTH', () => {
    expect(
      statusReducer(state, {
        type: 'RECEIVE_MONTH'
      })
    ).toEqual(Object.assign({}, state, {fetchSuccess: true, isFetching: false}))
  })
})
