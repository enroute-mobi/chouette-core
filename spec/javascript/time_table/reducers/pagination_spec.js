import paginationReducer from '../../../../app/packs/src/time_tables/reducers/pagination'

const dispatch = function(){}

let pagination = {
  currentPage: "1982-02-15",
  periode_range: ["1982-02-01", "1982-02-02", "1982-02-03"],
  stateChanged: false
}

let state = {}

describe('pagination reducer', () => {
  beforeEach(() => {
    state = {
      currentPage: "",
      periode_range: [],
      stateChanged: false
    }
  })

  it('should return the initial state', () => {
    expect(
      paginationReducer(undefined, {})
    ).toEqual({})
  })

  it('should handle RECEIVE_TIME_TABLES', () => {
    let json = [{
      current_periode_range: "1982-02-15",
      periode_range: ["1982-02-01", "1982-02-02", "1982-02-03"]
    }]
    expect(
      paginationReducer(state, {
        type: 'RECEIVE_TIME_TABLES',
        json
      })
    ).toEqual(Object.assign({}, state, {currentPage: json.current_periode_range, periode_range: json.periode_range}))
  })

  it('should handle GO_TO_PREVIOUS_PAGE', () => {
    let nextPage = -1
    let newPage = pagination.periode_range[pagination.periode_range.indexOf(pagination.currentPage) + nextPage]

    expect(
      paginationReducer(state, {
        type: 'GO_TO_PREVIOUS_PAGE',
        dispatch,
        pagination,
        nextPage: false
      })
    ).toEqual(Object.assign({}, state,  {currentPage : newPage, stateChanged: false}))
  })
  it('should handle GO_TO_NEXT_PAGE', () => {
    let nextPage = -1
    let newPage = pagination.periode_range[pagination.periode_range.indexOf(pagination.currentPage) + nextPage]

    expect(
      paginationReducer(state, {
        type: 'GO_TO_NEXT_PAGE',
        dispatch,
        pagination,
        nextPage: false
      })
    ).toEqual(Object.assign({}, state,  {currentPage : newPage, stateChanged: false}))
  })

  it('should handle CHANGE_PAGE', () => {
    let page = "1982-02-15"
    expect(
      paginationReducer(state, {
        type: 'CHANGE_PAGE',
        dispatch,
        page
      })
    ).toEqual(Object.assign({}, state, {currentPage : page, stateChanged: false}))
  })

  it('should handle ADD_INCLUDED_DATE', () => {
    expect(
      paginationReducer(state, {
        type: 'ADD_INCLUDED_DATE'
      })
    ).toEqual(Object.assign({}, state, {stateChanged: true}))
  })

  it('should handle REMOVE_INCLUDED_DATE', () => {
    expect(
      paginationReducer(state, {
        type: 'REMOVE_INCLUDED_DATE'
      })
    ).toEqual(Object.assign({}, state, {stateChanged: true}))
  })

  it('should handle ADD_EXCLUDED_DATE', () => {
    expect(
      paginationReducer(state, {
        type: 'ADD_EXCLUDED_DATE'
      })
    ).toEqual(Object.assign({}, state, {stateChanged: true}))
  })

  it('should handle REMOVE_EXCLUDED_DATE', () => {
    expect(
      paginationReducer(state, {
        type: 'REMOVE_EXCLUDED_DATE'
      })
    ).toEqual(Object.assign({}, state, {stateChanged: true}))
  })

  it('should handle DELETE_PERIOD', () => {
    expect(
      paginationReducer(state, {
        type: 'DELETE_PERIOD'
      })
    ).toEqual(Object.assign({}, state, {stateChanged: true}))
  })
  it('should handle VALIDATE_PERIOD_FORM', () => {
    expect(
      paginationReducer(state, {
        type: 'VALIDATE_PERIOD_FORM'
      })
    ).toEqual(Object.assign({}, state, {stateChanged: true}))
  })
  it('should handle UPDATE_COMMENT', () => {
    expect(
      paginationReducer(state, {
        type: 'UPDATE_COMMENT'
      })
    ).toEqual(Object.assign({}, state, {stateChanged: true}))
  })
  it('should handle UPDATE_COLOR', () => {
    expect(
      paginationReducer(state, {
        type: 'UPDATE_COLOR'
      })
    ).toEqual(Object.assign({}, state, {stateChanged: true}))
  })
})
