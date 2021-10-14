import jpReducer from '../../../../app/packs/src/journey_patterns/reducers/journeyPatterns'

let state = []
let fakeStopPoints = [{
  area_type : "lda",
  checked : false,
  id : 45289,
  name : "Clichy Levallois",
  object_id : "FR:92044:LDA:72073:STIF",
  position : 0,
},{
  area_type : "lda",
  checked : false,
  id : 40534,
  name : "Thomas Lemaître",
  object_id : "FR:92050:LDA:70915:STIF",
  position : 1,
}]


describe('journeyPatterns reducer', () => {
  beforeEach(()=>{
    state = [
      {
        deletable: false,
        name: 'm1',
        object_id : 'o1',
        published_name: 'M1',
        registration_number: '',
        stop_points: fakeStopPoints,
        costs: {

        }
      },
      {
        deletable: false,
        name: 'm2',
        object_id : 'o2',
        published_name: 'M2',
        registration_number: '',
        stop_points: fakeStopPoints,
        costs: {
          "1-2": {
            distance: 0,
            time: 10,
          }
        }
      }
    ]
  })

  it('should return the initial state', () => {
    expect(
      jpReducer(undefined, {})
    ).toEqual([])
  })

  it('should handle ADD_JOURNEYPATTERN', () => {
    let fakeData = {
      name: {value : 'm3'},
      published_name: {value: 'M3'},
      registration_number: {value: ''},
      shape: {id: 1, name: "test", uuid: "test-uuid"}
    }

    expect(
      jpReducer(state, {
        type: 'ADD_JOURNEYPATTERN',
        data: fakeData
      })
    ).toEqual([{
      name : 'm3',
      published_name: 'M3',
      registration_number: '',
      deletable: false,
      costs: {},
      shape: {id: 1, name: "test", uuid: "test-uuid"}
    }, ...state])
  })

  it('should handle UPDATE_CHECKBOX_VALUE', () => {
    let newFirstStopPoint = Object.assign({}, fakeStopPoints[0], {checked: !fakeStopPoints[0].checked} )
    let newStopPoints = [newFirstStopPoint, fakeStopPoints[1]]
    let newState = Object.assign({}, state[0], {stop_points: newStopPoints})
    expect(
      jpReducer(state, {
        type: 'UPDATE_CHECKBOX_VALUE',
        id: 45289,
        index: 0,
        position: "0"
      })
    ).toEqual([newState, state[1]])
  })

  it('should handle UPDATE_JOURNEYPATTERN_COSTS', () => {
    const costs = {
      "1-2": {
        distance: 1
      }
    }
    const new_costs = {
      "1-2": {
        distance: 1,
        time: 10,
      }
    }
    const new_state = Object.assign({}, state[1], {costs: new_costs})
    expect(
      jpReducer(state, {
        type: 'UPDATE_JOURNEYPATTERN_COSTS',
        index: 1,
        costs
      })
    ).toEqual([state[0], new_state])
  })

  it('should handle RECEIVE_ROUTE_COSTS', () => {
    const costs = {
      "1-2": {
        distance: 1,
        time: 9,
      },
      "2-3": {
        distance: 23,
        time: 10
      }
    }
    const new_costs = {
      "1-2": {
        distance: 0,
        time: 10,
      },
      "2-3": {
        distance: 23,
        time: 10
      }
    }
    const new_state = Object.assign({}, state[1], {costs: new_costs})
    expect(
      jpReducer(state, {
        type: 'RECEIVE_ROUTE_COSTS',
        costs,
        key: '2-3',
        index: 1
      })
    ).toEqual([state[0], new_state])
  })

  it('should handle RECEIVE_ROUTE_COSTS when cost key is missing', () => {
    const costs = {
      "1-2": {
        distance: 1,
        time: 9,
      },
      "2-3": {
        distance: 23,
        time: 10
      }
    }
    const new_costs = {
      "1-2": {
        distance: 0,
        time: 10,
      },
      "3-4": {
        distance: 0,
        time: 0
      }
    }
    const new_state = Object.assign({}, state[1], {costs: new_costs})
    expect(
      jpReducer(state, {
        type: 'RECEIVE_ROUTE_COSTS',
        costs,
        key: '3-4',
        index: 1
      })
    ).toEqual([state[0], new_state])
  })

  it('should handle DELETE_JOURNEYPATTERN', () => {
    expect(
      jpReducer(state, {
        type: 'DELETE_JOURNEYPATTERN',
        index: 1
      })
    ).toEqual([state[0], Object.assign({}, state[1], {deletable: true})])
  })
  it('should handle SAVE_MODAL', () => {
    let newState = Object.assign({}, state[0], {name: 'p1', published_name: 'P1', registration_number: 'PP11'})
    expect(
      jpReducer(state, {
        type: 'SAVE_MODAL',
        data: {
          name: {value: 'p1'},
          published_name: {value: 'P1'},
          registration_number: {value: 'PP11'}
        },
        index: 0
      })
    ).toEqual([newState, state[1]])
  })
})
