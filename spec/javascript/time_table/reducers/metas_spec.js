import metasReducer from '../../../../app/packs/src/time_tables/reducers/metas'

let state = {}

describe('metas reducer', () => {
  beforeEach(() => {
    state = {
      comment: 'test',
      day_types: [true, true, true, true, true, true, true],
      color: 'blue'
    }
  })

  it('should return the initial state', () => {
    expect(
      metasReducer(undefined, {})
    ).toEqual({})
  })

  it('should handle UPDATE_DAY_TYPES', () => {
    const arr = [false, false, true, true, true, true, true]
    expect(
      metasReducer(state, {
        type: 'UPDATE_DAY_TYPES',
        dayTypes: arr
      })
    ).toEqual(Object.assign({}, state, {day_types: arr, calendar: null}))
  })

  it('should handle UPDATE_COMMENT', () => {
    expect(
      metasReducer(state, {
        type: 'UPDATE_COMMENT',
        comment: 'title'
      })
    ).toEqual(Object.assign({}, state, {comment: 'title'}))
  })

  it('should handle UPDATE_COLOR', () => {
    expect(
      metasReducer(state, {
        type: 'UPDATE_COLOR',
        color: '#ffffff'
      })
    ).toEqual(Object.assign({}, state, {color: '#ffffff'}))
  })
})