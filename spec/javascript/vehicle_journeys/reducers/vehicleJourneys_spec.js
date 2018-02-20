import vjReducer from '../../../../app/javascript/vehicle_journeys/reducers/vehicleJourneys'

let state = []
let stateModal = {
  type: '',
  modalProps: {},
  confirmModal: {}
}
let fakeFootnotes = [{
  id: 1,
  code: 1,
  label: "1"
},{
  id: 2,
  code: 2,
  label: "2"
}]

let fakeTimeTables = [{
  published_journey_name: 'test 1',
  objectid: '1'
},{
  published_journey_name: 'test 2',
  objectid: '2'
},{
  published_journey_name: 'test 3',
  objectid: '3'
}]
let fakeVJAS = [{
  delta : 627,
  arrival_time : {
    hour: '11',
    minute: '55'
  },
  departure_time : {
    hour: '22',
    minute: '22'
  },
  stop_area_object_id : "FR:92024:ZDE:420553:STIF"
}]

describe('vehicleJourneys reducer', () => {
  beforeEach(()=>{
    state = [
      {
        journey_pattern_id: 1,
        published_journey_name: "vj1",
        objectid: '11',
        deletable: false,
        selected: true,
        footnotes: fakeFootnotes,
        time_tables: fakeTimeTables,
        vehicle_journey_at_stops: fakeVJAS
      },
      {
        journey_pattern_id: 2,
        published_journey_name: "vj2",
        objectid: '22',
        selected: false,
        deletable: false,
        footnotes: fakeFootnotes,
        time_tables: fakeTimeTables,
        vehicle_journey_at_stops: fakeVJAS
      }
    ]
  })

  it('should return the initial state', () => {
    expect(
      vjReducer(undefined, {})
    ).toEqual([])
  })


  it('should handle ADD_VEHICLEJOURNEY', () => {
    let pristineVjasList = [{
      delta : 0,
      arrival_time : {
        hour: "00",
        minute: "00"
      },
      departure_time : {
        hour: "00",
        minute: "00"
      },
      stop_point_objectid: 'test',
      stop_area_cityname: 'city',
      dummy: true
    }]
    let fakeData = {
      published_journey_name: {value: 'test'},
      published_journey_identifier: {value : ''},
      custom_fields: {
        foo: {
          value: 12
        }
      }
    }
    let fakeSelectedJourneyPattern = {id: "1"}
    let fakeSelectedCompany = {name: "ALBATRANS"}
    expect(
      vjReducer(state, {
        type: 'ADD_VEHICLEJOURNEY',
        data: fakeData,
        selectedJourneyPattern: fakeSelectedJourneyPattern,
        stopPointsList: [{object_id: 'test', city_name: 'city'}],
        selectedCompany: fakeSelectedCompany
      })
    ).toEqual([{
      journey_pattern: fakeSelectedJourneyPattern,
      company: fakeSelectedCompany,
      published_journey_name: 'test',
      published_journey_identifier: '',
      short_id: '',
      objectid: '',
      footnotes: [],
      time_tables: [],
      purchase_windows: [],
      vehicle_journey_at_stops: pristineVjasList,
      selected: false,
      deletable: false,
      transport_mode: 'undefined',
      transport_submode: 'undefined',
      custom_fields: {
        foo: {
          value: 12
        }
      }
    }, ...state])
  })

  it('should handle ADD_VEHICLEJOURNEY with a start time and a fully timed JP', () => {
    let pristineVjasList = [{
      delta : 0,
      arrival_time : {
        hour: 22,
        minute: 59
      },
      departure_time : {
        hour: 22,
        minute: 59
      },
      stop_point_objectid: 'test-1',
      stop_area_cityname: 'city',
      dummy: false
    },
    {
      delta : 0,
      arrival_time : {
        hour: 23,
        minute: 2
      },
      departure_time : {
        hour: 23,
        minute: 12
      },
      departure_day_offset: -1,
      arrival_day_offset: -1,
      stop_point_objectid: 'test-2',
      stop_area_cityname: 'city',
      dummy: false
    },
    {
      delta : 0,
      arrival_time : {
        hour: "00",
        minute: "00"
      },
      departure_time : {
        hour: "00",
        minute: "00"
      },
      stop_point_objectid: 'test-3',
      stop_area_cityname: 'city',
      dummy: true
    },
    {
      delta : 0,
      arrival_time : {
        hour: 0,
        minute: 42
      },
      departure_time : {
        hour: 0,
        minute: 42
      },
      stop_point_objectid: 'test-4',
      stop_area_cityname: 'city',
      dummy: false
    }]
    let fakeData = {
      published_journey_name: {value: 'test'},
      published_journey_identifier: {value : ''},
      "start_time.hour": {value : '22'},
      "start_time.minute": {value : '59'}
    }
    let fakeSelectedJourneyPattern = {
      id: "1",
      full_schedule: true,
      stop_areas: [
        {stop_area_short_description: {id: 1}},
        {stop_area_short_description: {id: 2}},
        {stop_area_short_description: {id: 4}},
      ],
      costs: {
        "1-2": {
          distance: 10,
          time: 63
        },
        "2-4": {
          distance: 10,
          time: 30
        }
      }
    }
    let fakeSelectedCompany = {name: "ALBATRANS"}
    expect(
      vjReducer(state, {
        type: 'ADD_VEHICLEJOURNEY',
        data: fakeData,
        selectedJourneyPattern: fakeSelectedJourneyPattern,
        stopPointsList: [{object_id: 'test-1', city_name: 'city', stop_area_id: 1, id: 1, time_zone_offset: 0, waiting_time: null}, {object_id: 'test-2', city_name: 'city', stop_area_id: 2, id: 2, time_zone_offset: -3600, waiting_time: 10}, {object_id: 'test-3', city_name: 'city', stop_area_id: 3, id: 3, time_zone_offset: 0, waiting_time: 20}, {object_id: 'test-4', city_name: 'city', stop_area_id: 4, id: 4, time_zone_offset: 0}],
        selectedCompany: fakeSelectedCompany
      })
    ).toEqual([{
      journey_pattern: fakeSelectedJourneyPattern,
      company: fakeSelectedCompany,
      published_journey_name: 'test',
      published_journey_identifier: '',
      short_id: '',
      objectid: '',
      footnotes: [],
      time_tables: [],
      purchase_windows: [],
      vehicle_journey_at_stops: pristineVjasList,
      selected: false,
      custom_fields: undefined,
      deletable: false,
      transport_mode: 'undefined',
      transport_submode: 'undefined'
    }, ...state])
  })

  it('should handle ADD_VEHICLEJOURNEY with a start time and a fully timed JP but the minutes are not set', () => {
    let pristineVjasList = [{
      delta : 0,
      arrival_time : {
        hour: 22,
        minute: 0
      },
      departure_time : {
        hour: 22,
        minute: 0
      },
      stop_point_objectid: 'test-1',
      stop_area_cityname: 'city',
      dummy: false
    },
    {
      delta : 0,
      arrival_time : {
        hour: 22,
        minute: 3
      },
      departure_time : {
        hour: 22,
        minute: 3
      },
      stop_point_objectid: 'test-2',
      stop_area_cityname: 'city',
      dummy: false
    }]
    let fakeData = {
      published_journey_name: {value: 'test'},
      published_journey_identifier: {value : ''},
      "start_time.hour": {value : '22'},
      "start_time.minute": {value : ''}
    }
    let fakeSelectedJourneyPattern = {
      id: "1",
      full_schedule: true,
      stop_areas: [
        {stop_area_short_description: {id: 1}},
        {stop_area_short_description: {id: 2}},
      ],
      costs: {
        "1-2": {
          distance: 10,
          time: 63
        },
      }
    }
    let fakeSelectedCompany = {name: "ALBATRANS"}
    expect(
      vjReducer(state, {
        type: 'ADD_VEHICLEJOURNEY',
        data: fakeData,
        selectedJourneyPattern: fakeSelectedJourneyPattern,
        stopPointsList: [{object_id: 'test-1', city_name: 'city', stop_area_id: 1, id: 1, time_zone_offset: 0}, {object_id: 'test-2', city_name: 'city', stop_area_id: 2, id: 2, time_zone_offset: -3600}],
        selectedCompany: fakeSelectedCompany
      })
    ).toEqual([{
      journey_pattern: fakeSelectedJourneyPattern,
      company: fakeSelectedCompany,
      published_journey_name: 'test',
      published_journey_identifier: '',
      short_id: '',
      objectid: '',
      footnotes: [],
      time_tables: [],
      purchase_windows: [],
      vehicle_journey_at_stops: pristineVjasList,
      selected: false,
      custom_fields: undefined,
      deletable: false,
      transport_mode: 'undefined',
      transport_submode: 'undefined'
    }, ...state])
  })

  it('should handle RECEIVE_VEHICLE_JOURNEYS', () => {
    expect(
      vjReducer(state, {
        type: 'RECEIVE_VEHICLE_JOURNEYS',
        json: state
      })
    ).toEqual(state)
  })

  it('should handle UPDATE_TIME', () => {
    const val = '33', subIndex = 0, index = 0, timeUnit = 'minute', isDeparture = true, isArrivalsToggled = true
    let newVJAS = [{
      delta: 638,
      arrival_time : {
        hour: '11',
        minute: '55'
      },
      departure_time : {
        hour: '22',
        minute: '33'
      },
      stop_area_object_id : "FR:92024:ZDE:420553:STIF"
    }]
    let newVJ = Object.assign({}, state[0], {vehicle_journey_at_stops: newVJAS})
    expect(
      vjReducer(state, {
        type: 'UPDATE_TIME',
        val,
        subIndex,
        index,
        timeUnit,
        isDeparture,
        isArrivalsToggled
      })
    ).toEqual([newVJ, state[1]])
  })

  it('should handle SELECT_VEHICLEJOURNEY', () => {
    const index = 1
    const newVJ = Object.assign({}, state[1], {selected: true})
    expect(
      vjReducer(state, {
        type: 'SELECT_VEHICLEJOURNEY',
        index
      })
    ).toEqual([state[0], newVJ])
  })

  it('should handle CANCEL_SELECTION', () => {
    const index = 1
    const newVJ = Object.assign({}, state[0], {selected: false})
    expect(
      vjReducer(state, {
        type: 'CANCEL_SELECTION',
        index
      })
    ).toEqual([newVJ, state[1]])
  })

  it('should handle DELETE_VEHICLEJOURNEYS', () => {
    const newVJ = Object.assign({}, state[0], {deletable: true, selected: false})
    expect(
      vjReducer(state, {
        type: 'DELETE_VEHICLEJOURNEYS'
      })
    ).toEqual([newVJ, state[1]])
  })

  it('should handle SHIFT_VEHICLEJOURNEY', () => {
    let newVJAS = [{
      delta: 627,
      arrival_time : {
        hour: '12',
        minute: '00'
      },
      departure_time : {
        hour: '22',
        minute: '27'
      },
      stop_area_object_id : "FR:92024:ZDE:420553:STIF"
    }]
    let addtionalTime = 5
    let newVJ = Object.assign({}, state[0], {vehicle_journey_at_stops: newVJAS})
    expect(
      vjReducer(state, {
        type: 'SHIFT_VEHICLEJOURNEY',
        addtionalTime
      })
    ).toEqual([newVJ, state[1]])
  })

  it('should handle DUPLICATE_VEHICLEJOURNEY', () => {
    let newVJAS = [{
      delta: 627,
      arrival_time : {
        hour: '12',
        minute: '01'
      },
      departure_time : {
        hour: '22',
        minute: '28'
      },
      stop_area_object_id : "FR:92024:ZDE:420553:STIF"
    }]
    let departureDelta = 1
    let addtionalTime = 5
    let duplicateNumber = 1

    let newVJ = Object.assign({}, state[0], {vehicle_journey_at_stops: newVJAS, selected: false})
    newVJ.published_journey_name = state[0].published_journey_name + '-0'
    delete newVJ['objectid']
    expect(
      vjReducer(state, {
        type: 'DUPLICATE_VEHICLEJOURNEY',
        addtionalTime,
        duplicateNumber,
        departureDelta
      })
    ).toEqual([state[0], newVJ, state[1]])
  })

  it('should handle EDIT_VEHICLEJOURNEY', () => {
    let custom_fields = {
      foo: {
        value: 12
      }
    }
    let fakeData = {
      published_journey_name: {value : 'test'},
      published_journey_identifier: {value: 'test'},
      custom_fields: {foo: {value: 12}}
    }
    let fakeSelectedCompany : {name : 'ALBATRANS'}
    let newVJ = Object.assign({}, state[0], {company: fakeSelectedCompany, published_journey_name: fakeData.published_journey_name.value, published_journey_identifier: fakeData.published_journey_identifier.value, custom_fields})
    expect(
      vjReducer(state, {
        type: 'EDIT_VEHICLEJOURNEY',
        data: fakeData
      })
    ).toEqual([newVJ, state[1]])
  })

  it('should handle EDIT_VEHICLEJOURNEYS_TIMETABLES', () => {
    let newState = JSON.parse(JSON.stringify(state))
    newState[0].time_tables = [fakeTimeTables[0]]
    expect(
      vjReducer(state, {
        type: 'EDIT_VEHICLEJOURNEYS_TIMETABLES',
        vehicleJourneys: state,
        timetables: [fakeTimeTables[0]]
      })
    ).toEqual(newState)
  })

  it('should handle EDIT_VEHICLEJOURNEYS_PURCHASE_WINDOWS', () => {
    let newState = JSON.parse(JSON.stringify(state))
    newState[0].purchase_windows = [fakeTimeTables[0]]
    expect(
      vjReducer(state, {
        type: 'EDIT_VEHICLEJOURNEYS_PURCHASE_WINDOWS',
        vehicleJourneys: state,
        purchase_windows: [fakeTimeTables[0]]
      })
    ).toEqual(newState)
  })
})
