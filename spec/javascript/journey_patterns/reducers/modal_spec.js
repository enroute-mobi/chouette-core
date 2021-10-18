import modalReducer from '../../../../app/packs/src/journey_patterns/reducers/modal'

let state = {}

let fakeJourneyPattern = {
  name: 'jp_test 1',
  object_id: 'jp_test:JourneyPattern:1',
  published_name: 'jp_test publishedname 1',
  registration_number: 'jp_test registrationnumber 1',
  stop_points: [],
  deletable: false,
  shape: undefined
}

const cb = function(){}

describe('modal reducer', () => {
  beforeEach(() => {
    state = {
      type: '',
      modalProps: {},
      confirmModal: {}
    }
  })

  it('should return the initial state', () => {
    expect(
      modalReducer(undefined, {})
    ).toEqual({})
  })

  it('should handle OPEN_CONFIRM_MODAL', () => {
    let newState = Object.assign({}, state, {
      type: 'confirm',
      confirmModal: {
        callback: cb
      }
    })
    expect(
      modalReducer(state, {
        type: 'OPEN_CONFIRM_MODAL',
        callback: cb
      })
    ).toEqual(newState)
  })

  it('should handle EDIT_JOURNEYPATTERN_MODAL', () => {
    let newState = Object.assign({}, state, {
      type: 'edit',
      modalProps: {
        index: 0,
        journeyPattern: fakeJourneyPattern
      },
      confirmModal: {}
    })
    expect(
      modalReducer(state, {
        type: 'EDIT_JOURNEYPATTERN_MODAL',
        index: 0,
        journeyPattern : fakeJourneyPattern
      })
    ).toEqual(newState)
  })

  it('should handle CREATE_JOURNEYPATTERN_MODAL', () => {
    expect(
      modalReducer(state, {
        type: 'CREATE_JOURNEYPATTERN_MODAL'
      })
    ).toEqual(Object.assign({}, state, { type: 'create' }))
  })

  it('should handle DELETE_JOURNEYPATTERN', () => {
    expect(
      modalReducer(state, {
        type: 'DELETE_JOURNEYPATTERN',
        index: 0
      })
    ).toEqual(state)
  })

  it('should handle SAVE_MODAL', () => {
    expect(
      modalReducer(state, {
        type: 'SAVE_MODAL',
        index: 0,
        data: {}
      })
    ).toEqual(state)
  })

  it('should handle CLOSE_MODAL', () => {
    expect(
      modalReducer(state, {
        type: 'CLOSE_MODAL'
      })
    ).toEqual(state)
  })

  it('should handle SELECT_SHAPE_EDIT_MODAL', () => {
    let fakeShape = {id: 1, uuid: "00000", name: null}
    let initialState = Object.assign({}, state, {modalProps : { ...state.modalProps, journeyPattern: fakeJourneyPattern }})

    let newState = Object.assign({}, initialState, {
      modalProps: {
        journeyPattern: Object.assign({}, fakeJourneyPattern, {shape: fakeShape})
      }
    })

    expect(
      modalReducer(initialState, {
        type: 'SELECT_SHAPE_EDIT_MODAL',
        selectedItem: fakeShape
      })
    ).toEqual(newState)
  })

  it('should handle UNSELECT_SHAPE_EDIT_MODAL', () => {
    let fakeShape = {id: 1, uuid: "00000", name: null}
    let initialState = Object.assign({}, state, {modalProps : { ...state.modalProps, journeyPattern: {...fakeJourneyPattern, shape: fakeShape} }})

    let newState = Object.assign({}, initialState, {
      modalProps: {
        journeyPattern: Object.assign({}, fakeJourneyPattern, {shape: undefined})
      }
    })

    expect(
      modalReducer(initialState, {
        type: 'UNSELECT_SHAPE_EDIT_MODAL'
      })
    ).toEqual(newState)
  })
})
