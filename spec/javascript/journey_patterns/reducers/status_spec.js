import statusReducer from '../../../../app/packs/src/journey_patterns/reducers/status'

let state = {}

let pagination = {
  page : 2,
  totalCount : 25,
  stateChanged: false,
  perPage: 12
}
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

  it('should handle RECEIVE_JOURNEY_PATTERNS', () => {
    expect(
      statusReducer(state, {
        type: 'RECEIVE_JOURNEY_PATTERNS'
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
