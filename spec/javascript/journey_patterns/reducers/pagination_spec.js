import reducer from '../../../../app/packs/src/journey_patterns/reducers/pagination'

const diff = 1
let state = {
  page : 2,
  totalCount : 50,
  stateChanged: false,
  perPage: 20
}
let pagination = Object.assign({}, state)
const dispatch = function(){}

describe('pagination reducer, given parameters allowing page change', () => {

  it('should return the initial state', () => {
    expect(
      reducer(undefined, {})
    ).toEqual({})
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

describe('pagination reducer, given parameters changing totalCount', () => {

  it('should return UPDATE_TOTAL_COUNT and update totalCount', () => {
    expect(
      reducer(state, {
        type: 'UPDATE_TOTAL_COUNT',
        diff
      })
    ).toEqual(Object.assign({}, state, {totalCount: state.totalCount - diff}))
  })
})
