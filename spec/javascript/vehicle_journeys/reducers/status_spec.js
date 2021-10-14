import statusReducer from '../../../../app/packs/src/vehicle_journeys/reducers/status'

let state = {}

const dispatch = function(){}

describe('status reducer', () => {
  beforeEach(() => {
    state = {
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

  it('should handle RECEIVE_VEHICLE_JOURNEYS', () => {
    expect(
      statusReducer(state, {
        type: 'RECEIVE_VEHICLE_JOURNEYS'
      })
    ).toEqual(Object.assign({}, state, {fetchSuccess: true, isFetching: false}))
  })

  it('should handle FETCH_API', () => {
    expect(
      statusReducer(state, {
        type: 'FETCH_API'
      })
    ).toEqual(Object.assign({}, state, {isFetching: true}))
  })

})
