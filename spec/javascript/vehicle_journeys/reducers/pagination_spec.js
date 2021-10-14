import reducer from '../../../../app/packs/src/vehicle_journeys/reducers/pagination'

const diff = 1
let state = {
  page : 2,
  totalCount : 25,
  stateChanged: false,
  perPage: 12
}
let pagination = Object.assign({}, state)
const dispatch = function(){}

describe('pagination reducer, given parameters allowing page change', () => {

  it('should return the initial state', () => {
    expect(
      reducer(undefined, {})
    ).toEqual({})
  })

  it('should handle RECEIVE_TOTAL_COUNT', () => {
    expect(
      reducer(state, {
        type: 'RECEIVE_TOTAL_COUNT',
        total: 1
      })
    ).toEqual(Object.assign({}, state, {totalCount: 1}))
  })

  it('should handle RESET_PAGINATION', () => {
    expect(
      reducer(state, {
        type: 'RESET_PAGINATION',
      })
    ).toEqual(Object.assign({}, state, {page: 1}))
  })

  it('should handle UPDATE_TOTAL_COUNT', () => {
    expect(
      reducer(state, {
        type: 'UPDATE_TOTAL_COUNT',
        diff: 1
      })
    ).toEqual(Object.assign({}, state, {totalCount: 24}))
  })

  it('should handle GO_TO_NEXT_PAGE and change state', () => {
    expect(
      reducer(state, {
        type: 'GO_TO_NEXT_PAGE',
        dispatch,
        pagination,
        nextPage : true
      })
    ).toEqual(Object.assign({}, state, {page : state.page + 1, stateChanged: false}))
  })

  it('should return GO_TO_PREVIOUS_PAGE and change state', () => {
    expect(
      reducer(state, {
        type: 'GO_TO_PREVIOUS_PAGE',
        dispatch,
        pagination,
        nextPage : false
      })
    ).toEqual(Object.assign({}, state, {page : state.page - 1, stateChanged: false}))
  })

  it('should handle UPDATE_TIME', () => {
    const val = '33', subIndex = 0, index = 0, timeUnit = 'minute', isDeparture = true, isArrivalsToggled = true
    expect(
      reducer(state, {
        type: 'UPDATE_TIME',
        val,
        subIndex,
        index,
        timeUnit,
        isDeparture,
        isArrivalsToggled
      })
    ).toEqual(Object.assign({}, state, {stateChanged: true}))
  })

})


describe('pagination reducer, given parameters not allowing to go to previous page', () => {

  beforeEach(()=>{
    state.page = 1
    pagination.page = 1
  })

  it('should return GO_TO_PREVIOUS_PAGE and not change state', () => {
    expect(
      reducer(state, {
        type: 'GO_TO_PREVIOUS_PAGE',
        dispatch,
        pagination,
        nextPage : false
      })
    ).toEqual(state)
  })
})

describe('pagination reducer, given parameters not allowing to go to next page', () => {

  beforeEach(()=>{
    state.page = 3
    pagination.page = 3
  })

  it('should return GO_TO_NEXT_PAGE and not change state', () => {
    expect(
      reducer(state, {
        type: 'GO_TO_NEXT_PAGE',
        dispatch,
        pagination,
        nextPage : true
      })
    ).toEqual(state)
  })
})
