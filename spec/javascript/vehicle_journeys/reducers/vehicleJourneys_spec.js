import vjReducer from '../../../../app/packs/src/vehicle_journeys/reducers/vehicleJourneys'
import actions from '../../../../app/packs/src/vehicle_journeys/actions/index'

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
let fakeVJAS = [
  {
  delta : 0,
  arrival_time : {
    hour: '07',
    minute: '02'
  },
  departure_time : {
    hour: '07',
    minute: '02'
  },
  stop_area_object_id: "chouette:StopArea:8000b367-e07c-43b8-b1be-766f1bfe542a:LOC",
  dummy: false,
  stop_point_id: 1,
  stop_area_id: 1,
  specific_stop_area_id: undefined
},
{
  delta: 627,
  arrival_time: {
    hour: '11',
    minute: '55'
  },
  departure_time: {
    hour: '22',
    minute: '22'
  },
  stop_area_object_id: "chouette:StopArea:c9d50c53-e4f4-4ccb-b5bd-6b80c4a3e6d0:LOC",
  dummy: false,
  stop_point_id: 2,
  stop_area_id: 2,
  specific_stop_area_id: undefined
},
{
  delta: 0,
  arrival_time: {
    hour: '23',
    minute: '00'
  },
  departure_time: {
    hour: '23',
    minute: '00'
  },
  stop_area_object_id: "chouette:StopArea:25821842-d8b9-4171-81d2-9b7f905c5291:LOC",
  dummy: false,
  stop_point_id: 3,
  stop_area_id: 3,
  specific_stop_area_id: undefined
}]

describe('vehicleJourneys reducer', () => {
  beforeEach(()=>{
    state = [
      {
        journey_pattern_id: 1,
        published_journey_name: "vj1",
        objectid: '11',
        short_id: '11',
        deletable: false,
        selected: true,
        footnotes: fakeFootnotes,
        time_tables: fakeTimeTables,
        vehicle_journey_at_stops: fakeVJAS,
        index: 0,
        custom_fields: {foo: {value: 1}}
      },
      {
        journey_pattern_id: 2,
        published_journey_name: "vj2",
        objectid: '22',
        short_id: '22',
        selected: false,
        deletable: false,
        footnotes: fakeFootnotes,
        time_tables: fakeTimeTables,
        vehicle_journey_at_stops: fakeVJAS,
        index: 1,
        custom_fields: {foo: {value: 1}}
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
        hour: 0,
        minute: 0
      },
      departure_time : {
        hour: 0,
        minute: 0
      },
      stop_point_objectid: 'test',
      stop_area_cityname: 'city',
      dummy: false
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
    let fakeSelectedJourneyPattern = { id: "1", stop_areas: [{stop_area_short_description: { object_id: '001', position: 0}}]}
    let fakeSelectedCompany = {name: "ALBATRANS"}
    expect(
      vjReducer(state, {
        type: 'ADD_VEHICLEJOURNEY',
        data: fakeData,
        selectedJourneyPattern: fakeSelectedJourneyPattern,
        stopPointsList: [{object_id: 'test', city_name: 'city', area_object_id: '001', position: 0}],
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
      referential_codes: [],
      line_notices: [],
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

  it('should handle ADD_VEHICLEJOURNEY with a loop in the route', () => {
    let pristineVjasList = [{
      delta : 0,
      arrival_time : {
        hour: 0,
        minute: 0
      },
      departure_time : {
        hour: 0,
        minute: 0
      },
      stop_point_objectid: 'test',
      stop_area_cityname: 'city',
      dummy: false,
      stop_point_id: 'sp1',
      stop_area_id: 'sa1'
    },
    {
      delta : 0,
      arrival_time : {
        hour: 0,
        minute: 0
      },
      departure_time : {
        hour: 0,
        minute: 0
      },
      stop_point_objectid: 'test2',
      stop_area_cityname: 'city',
      dummy: false,
      stop_point_id: 'sp2',
      stop_area_id: 'sa2'
    },
    {
      delta : 0,
      arrival_time : {
        hour: '00',
        minute: '00'
      },
      departure_time : {
        hour: '00',
        minute: '00'
      },
      stop_point_objectid: 'test',
      stop_area_cityname: 'city',
      dummy: true,
      stop_point_id: 'sp3',
      stop_area_id: 'sa1'
    },
    {
      delta: 0,
      arrival_time: {
        hour: 0,
        minute: 0
      },
      departure_time: {
        hour: 0,
        minute: 0
      },
      stop_point_objectid: 'test',
      stop_area_cityname: 'city',
      dummy: false,
      stop_point_id: 'sp4',
      stop_area_id: 'sa3'
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
    let fakeSelectedJourneyPattern = {
      id: "1",
      stop_areas: [
        {
          stop_area_short_description: {
            position: 0,
            id: 'sa1',
            object_id: '001'
          }
        },
        {
          stop_area_short_description: {
            position: 1,
            id: 'sa2',
            object_id: '002'
          }
        },
        {
          stop_area_short_description: {
            position: 3,
            id: 'sa3',
            object_id: '003'
          }
        }
      ]
    }
    let fakeSelectedCompany = {name: "ALBATRANS"}
    expect(
      vjReducer(state, {
        type: 'ADD_VEHICLEJOURNEY',
        data: fakeData,
        selectedJourneyPattern: fakeSelectedJourneyPattern,
        stopPointsList: [
          { object_id: 'test', city_name: 'city', id: 'sp1', area_object_id: '001', position: 0, stop_area_id: 'sa1'},
          { object_id: 'test2', city_name: 'city', id: 'sp2', area_object_id: '002', position: 1, stop_area_id: 'sa2'},
          { object_id: 'test', city_name: 'city', id: 'sp3', area_object_id: '001', position: 2, stop_area_id: 'sa1'},
          { object_id: 'test', city_name: 'city', id: 'sp4', area_object_id: '003', position: 3, stop_area_id: 'sa3'}
        ],
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
      referential_codes: [],
      line_notices: [],
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
      dummy: false,
      stop_point_id: 1,
      stop_area_id: 1
    },
    {
      delta : 10,
      arrival_time : {
        hour: 23,
        minute: 2
      },
      departure_time : {
        hour: 23,
        minute: 12
      },
      stop_point_objectid: 'test-2',
      stop_area_cityname: 'city',
      dummy: false,
      stop_point_id: 2,
      stop_area_id: 2
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
      dummy: true,
      stop_point_id: 3,
      stop_area_id: 3
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
      dummy: false,
      stop_point_id: 4,
      stop_area_id: 4
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
        {stop_area_short_description: {position: 0, id: 1, object_id: '001'}},
        { stop_area_short_description: { position: 1, id: 2, object_id: '002'}},
        { stop_area_short_description: { position: 3, id: 4, object_id: '004'}},
      ],
      costs: {
        "1-2": {
          distance: 10,
          time: 63*60
        },
        "2-4": {
          distance: 10,
          time: 30*60
        }
      }
    }
    let fakeSelectedCompany = {name: "ALBATRANS"}
    expect(
      vjReducer(state, {
        type: 'ADD_VEHICLEJOURNEY',
        data: fakeData,
        selectedJourneyPattern: fakeSelectedJourneyPattern,
        stopPointsList: [
          { object_id: 'test-1', city_name: 'city', stop_area_id: 1, id: 1, time_zone_offset: 0, waiting_time: 10, area_object_id: '001', position: 0 },
          { object_id: 'test-2', city_name: 'city', stop_area_id: 2, id: 2, time_zone_offset: -3600, waiting_time: 10, area_object_id: '002', position: 1 },
          { object_id: 'test-3', city_name: 'city', stop_area_id: 3, id: 3, time_zone_offset: 0, waiting_time: 20, area_object_id: '003', position: 2 },
          { object_id: 'test-4', city_name: 'city', stop_area_id: 4, id: 4, time_zone_offset: 0, waiting_time: 100, area_object_id: '004', position: 3}
        ],
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
      referential_codes: [],
      line_notices: [],
      vehicle_journey_at_stops: pristineVjasList,
      selected: false,
      custom_fields: undefined,
      deletable: false,
      transport_mode: 'undefined',
      transport_submode: 'undefined'
    }, ...state])
  })

  it('should handle ADD_VEHICLEJOURNEY with a start time and a fully timed JP not starting on the first stop', () => {
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
      stop_point_objectid: 'test-1',
      stop_area_cityname: 'city',
      dummy: true,
      stop_point_id: 1,
      stop_area_id: 1
    },
    {
      delta : 0,
      arrival_time : {
        hour: 23,
        minute: 2
      },
      departure_time : {
        hour: 23,
        minute: 2
      },
      stop_point_objectid: 'test-2',
      stop_area_cityname: 'city',
      dummy: false,
      stop_point_id: 2,
      stop_area_id: 2
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
      dummy: true,
      stop_point_id: 3,
      stop_area_id: 3
    },
    {
      delta : 0,
      arrival_time : {
        hour: 0,
        minute: 32
      },
      departure_time : {
        hour: 0,
        minute: 32
      },
      stop_point_objectid: 'test-4',
      stop_area_cityname: 'city',
      dummy: false,
      stop_point_id: 4,
      stop_area_id: 4
    }]
    let fakeData = {
      published_journey_name: {value: 'test'},
      published_journey_identifier: {value : ''},
      "start_time.hour": {value : '0'},
      "start_time.minute": {value : '2'}
    }
    let fakeSelectedJourneyPattern = {
      id: "1",
      full_schedule: true,
      stop_areas: [
        {stop_area_short_description: {id: 2, position: 1, object_id: '002'}},
        { stop_area_short_description: { id: 4, position: 3, object_id: '004'}},
      ],
      costs: {
        "2-4": {
          distance: 10,
          time: 30*60
        }
      }
    }
    let fakeSelectedCompany = {name: "ALBATRANS"}
    expect(
      vjReducer(state, {
        type: 'ADD_VEHICLEJOURNEY',
        data: fakeData,
        selectedJourneyPattern: fakeSelectedJourneyPattern,
        stopPointsList: [
          { object_id: 'test-1', city_name: 'city', stop_area_id: 1, id: 1, time_zone_offset: 0, waiting_time: 10, position: 0, area_object_id: '001' },
          { object_id: 'test-2', city_name: 'city', stop_area_id: 2, id: 2, time_zone_offset: -3600, waiting_time: 10, position: 1, area_object_id: '002' },
          { object_id: 'test-3', city_name: 'city', stop_area_id: 3, id: 3, time_zone_offset: 0, waiting_time: 20, position: 2, area_object_id: '003' },
          { object_id: 'test-4', city_name: 'city', stop_area_id: 4, id: 4, time_zone_offset: 0, waiting_time: 100, position: 3, area_object_id: '004'}
        ],
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
      referential_codes: [],
      line_notices: [],
      vehicle_journey_at_stops: pristineVjasList,
      selected: false,
      custom_fields: undefined,
      deletable: false,
      transport_mode: 'undefined',
      transport_submode: 'undefined'
    }, ...state])
  })

  it('should handle ADD_VEHICLEJOURNEY with a start time and a fully timed JP, and use user\'s TZ', () => {
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
      dummy: false,
      stop_point_id: 1,
      stop_area_id: 1
    },
    {
      delta : 10,
      arrival_time : {
        hour: 23,
        minute: 2
      },
      departure_time : {
        hour: 23,
        minute: 12
      },
      stop_point_objectid: 'test-2',
      stop_area_cityname: 'city',
      dummy: false,
      stop_point_id: 2,
      stop_area_id: 2
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
      dummy: true,
      stop_point_id: 3,
      stop_area_id: 3
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
      dummy: false,
      stop_point_id: 4,
      stop_area_id: 4
    }]
    let fakeData = {
      published_journey_name: {value: 'test'},
      published_journey_identifier: {value : ''},
      "start_time.hour": {value : '22'},
      "start_time.minute": {value : '59'},
      "tz_offset": {value : '-65'}
    }
    let fakeSelectedJourneyPattern = {
      id: "1",
      full_schedule: true,
      stop_areas: [
        {stop_area_short_description: {position: 0, id: 1, object_id: '001'}},
        { stop_area_short_description: { position: 1, id: 2, object_id: '002' }},
        { stop_area_short_description: { position: 3, id: 4, object_id: '004'}},
      ],
      costs: {
        "1-2": {
          distance: 10,
          time: 63*60
        },
        "2-4": {
          distance: 10,
          time: 30*60
        }
      }
    }
    let fakeSelectedCompany = {name: "ALBATRANS"}
    expect(
      vjReducer(state, {
        type: 'ADD_VEHICLEJOURNEY',
        data: fakeData,
        selectedJourneyPattern: fakeSelectedJourneyPattern,
        stopPointsList: [
          { object_id: 'test-1', city_name: 'city', stop_area_id: 1, id: 1, time_zone_offset: 0, waiting_time: null, area_object_id: '001', position: 0 },
          { object_id: 'test-2', city_name: 'city', stop_area_id: 2, id: 2, time_zone_offset: -3600, waiting_time: 10, area_object_id: '002', position: 1 },
          { object_id: 'test-3', city_name: 'city', stop_area_id: 3, id: 3, time_zone_offset: 0, waiting_time: 20, area_object_id: '003', position: 2 },
          { object_id: 'test-4', city_name: 'city', stop_area_id: 4, id: 4, time_zone_offset: 0, area_object_id: '004', position: 3}
        ],
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
      referential_codes: [],
      line_notices: [],
      vehicle_journey_at_stops: pristineVjasList,
      selected: false,
      custom_fields: undefined,
      deletable: false,
      transport_mode: 'undefined',
      transport_submode: 'undefined'
    }, ...state])
  })

  it('should handle ADD_VEHICLEJOURNEY with a start time and a fully timed JP but no time is set', () => {
    let pristineVjasList = [{
      delta : 0,
      arrival_time : {
        hour: 0,
        minute: 0
      },
      departure_time : {
        hour: 0,
        minute: 0
      },
      stop_point_objectid: 'test-1',
      stop_area_cityname: 'city',
      dummy: false,
      stop_point_id: 1,
      stop_area_id: 1
    },
    {
      delta : 0,
      arrival_time : {
        hour: 0,
        minute: 0
      },
      departure_time : {
        hour: 0,
        minute: 0
      },
      stop_point_objectid: 'test-2',
      stop_area_cityname: 'city',
      dummy: false,
      stop_point_id: 2,
      stop_area_id: 2
    }]
    let fakeData = {
      published_journey_name: {value: 'test'},
      published_journey_identifier: {value : ''},
      "start_time.hour": {value : ''},
      "start_time.minute": {value : ''}
    }
    let fakeSelectedJourneyPattern = {
      id: "1",
      full_schedule: true,
      stop_areas: [
        {stop_area_short_description: {position: 0, id: 1, object_id: '001'}},
        {stop_area_short_description: {position: 1, id: 2, object_id: '002'}}
      ],
      costs: {
        "1-2": {
          distance: 10,
          time: 63*60
        },
      }
    }
    let fakeSelectedCompany = {name: "ALBATRANS"}
    expect(
      vjReducer(state, {
        type: 'ADD_VEHICLEJOURNEY',
        data: fakeData,
        selectedJourneyPattern: fakeSelectedJourneyPattern,
        stopPointsList: [
          {object_id: 'test-1', city_name: 'city', stop_area_id: 1, id: 1, time_zone_offset: 0, position: 0, area_object_id: '001'},
          {object_id: 'test-2', city_name: 'city', stop_area_id: 2, id: 2, time_zone_offset: -3600, position: 1, area_object_id: '002'}
        ],
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
      referential_codes: [],
      line_notices: [],
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
      dummy: false,
      stop_area_id: 1,
      stop_point_id: 1
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
      dummy: false,
      stop_area_id: 2,
      stop_point_id: 2
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
        {stop_area_short_description: {position: 0, id: 1, object_id: '001'}},
        {stop_area_short_description: {position: 1, id: 2, object_id: '002'}}
      ],
      costs: {
        "1-2": {
          distance: 10,
          time: 63*60
        },
      }
    }
    let fakeSelectedCompany = {name: "ALBATRANS"}
    expect(
      vjReducer(state, {
        type: 'ADD_VEHICLEJOURNEY',
        data: fakeData,
        selectedJourneyPattern: fakeSelectedJourneyPattern,
        stopPointsList: [
          {object_id: 'test-1', city_name: 'city', stop_area_id: 1, id: 1, time_zone_offset: 0, position: 0, area_object_id: '001'},
          {object_id: 'test-2', city_name: 'city', stop_area_id: 2, id: 2, time_zone_offset: -3600, position: 1, area_object_id: '002'}
        ],
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
      referential_codes: [],
      line_notices: [],
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

  describe('UPDATE_TIME', () => {
    const val = '33', index = 0, timeUnit = 'minute', isDeparture = true, isArrivalsToggled = true, enforceConsistency = true

    context('first or last stop of a VJ', () => {
      set('subIndex', () => 0)
      set('updatedVJAS', () => {
        return {
          delta: 0,
          arrival_time: {
            hour: '07',
            minute: val
          },
          departure_time: {
            hour: '07',
            minute: val
          },
          stop_area_object_id: "chouette:StopArea:8000b367-e07c-43b8-b1be-766f1bfe542a:LOC",
          dummy: false,
          stop_point_id: 1,
          stop_area_id: 1,
          specific_stop_area_id: undefined
        }
      })

      it('should set departure time & arrival time to the same value', () => {
        const vjas = state[index]['vehicle_journey_at_stops']
        const newVJAS = [updatedVJAS, ...vjas.slice(1)]
        const newVJ = Object.assign({}, state[subIndex], { vehicle_journey_at_stops: newVJAS })
        let a = vjReducer(state, {
          type: 'UPDATE_TIME',
          val,
          subIndex,
          index,
          timeUnit,
          isDeparture,
          isArrivalsToggled,
          enforceConsistency
        })

        expect(
          vjReducer(state, {
            type: 'UPDATE_TIME',
            val,
            subIndex,
            index,
            timeUnit,
            isDeparture,
            isArrivalsToggled,
            enforceConsistency
          })
        ).toEqual([newVJ, state[1]])
      })
    })

    context('other stops', () => {
      set('subIndex', () => 1)
      set('updatedVJAS', () => {
        return {
          delta: 638,
          arrival_time: {
            hour: '11',
            minute: '55'
          },
          departure_time: {
            hour: '22',
            minute: '33'
          },
          stop_area_object_id: "chouette:StopArea:c9d50c53-e4f4-4ccb-b5bd-6b80c4a3e6d0:LOC",
          dummy: false,
          stop_point_id: 2,
          stop_area_id: 2,
          specific_stop_area_id: undefined
        }
      })

      it('should not set departure time & arrival time to the same value', () => {
        // const newState = JSON.parse(JSON.stringify(state))
        const vjas = state[index]['vehicle_journey_at_stops']
        const newVJAS = [...vjas.slice(0, 1), updatedVJAS, ...vjas.slice(2)]
        const newVJ = Object.assign({}, state[index], { vehicle_journey_at_stops: newVJAS })
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
    })
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

  it('should handle CANCEL_DELETION', () => {
    const newState = JSON.parse(JSON.stringify(state))
    newState[0]['deletable'] = true
    newState[0]['selected'] = true
    const newVJ = Object.assign({}, state[0], { deletable: false })
    expect(
      vjReducer(newState, {
        type: 'CANCEL_DELETION'
      })
    ).toEqual([newVJ, state[1]])
  })

  it('should handle SHIFT_VEHICLEJOURNEY', () => {
    const addtionalTime = 5
    const newState = JSON.parse(JSON.stringify(state))

    const newVJAS = newState[0].vehicle_journey_at_stops.map((vjas, index) => {
      let { hasAllAttributes, departure_time, arrival_time } = actions.scheduleToDates(vjas)
      let shiftedDT = new Date(departure_time.getTime() + (addtionalTime * 60000))
      let shiftedAT = new Date(arrival_time.getTime() + (addtionalTime * 60000))
      return {
        delta: vjas.delta,
        stop_area_object_id: vjas.stop_area_object_id,
        departure_time: {
          hour: actions.simplePad(shiftedDT.getHours()),
          minute: actions.simplePad(shiftedDT.getMinutes())
        },
        arrival_time: {
          hour: actions.simplePad(shiftedAT.getHours()),
          minute: actions.simplePad(shiftedAT.getMinutes())
        },
        dummy: false,
        stop_point_id: (index+1),
        stop_area_id: (index+1),
        specific_stop_area_id: undefined
      }
    })

    let newVJ = Object.assign({}, newState[0], {vehicle_journey_at_stops: newVJAS})
    expect(
      vjReducer(newState, {
        type: 'SHIFT_VEHICLEJOURNEY',
        addtionalTime
      })
    ).toEqual([newVJ, newState[1]])
  })

  it('should handle DUPLICATE_VEHICLEJOURNEY', () => {
    // const newState = JSON.parse(JSON.stringify(state))
    let departureDelta = 1
    let addtionalTime = 5
    let duplicateNumber = 1

    const newVJAS = state[0].vehicle_journey_at_stops.map((vjas, index) => {
      let { hasAllAttributes, departure_time, arrival_time } = actions.scheduleToDates(vjas)
      let shiftedDT = new Date(departure_time.getTime() + ((addtionalTime + departureDelta) * 60000))
      let shiftedAT = new Date(arrival_time.getTime() + ((addtionalTime + departureDelta) * 60000))
      return {
        delta: vjas.delta,
        stop_area_object_id: vjas.stop_area_object_id,
        departure_time: {
          hour: actions.simplePad(shiftedDT.getHours()),
          minute: actions.simplePad(shiftedDT.getMinutes())
        },
        arrival_time: {
          hour: actions.simplePad(shiftedAT.getHours()),
          minute: actions.simplePad(shiftedAT.getMinutes())
        },
        dummy: false,
        stop_point_id: (index+1),
        stop_area_id: (index+1),
        specific_stop_area_id: undefined
      }
    })

    let newVJ = Object.assign({}, state[0], {vehicle_journey_at_stops: newVJAS, selected: false})
    newVJ.published_journey_name = state[0].published_journey_name + '-0'
    newVJ.index = 1
    newVJ.referential_codes = []
    delete newVJ['objectid']
    delete newVJ['short_id']
    let newState
    expect(
      newState = vjReducer(state, {
        type: 'DUPLICATE_VEHICLEJOURNEY',
        addtionalTime,
        duplicateNumber,
        departureDelta
      })
    ).toEqual([state[0], newVJ, state[1]])
    newState[1].custom_fields.foo.value = 2
    expect(newState[0].custom_fields.foo.value).toEqual(1)
  })

  it('should handle EDIT_VEHICLEJOURNEY', () => {
    let custom_fields = {
      foo: {
        value: 12
      }
    }
    let fakeSelectedCompany = {name : 'ALBATRANS'}
    let fakeData = {
      published_journey_name: {value : 'test'},
      published_journey_identifier: {value: 'test'},
      custom_fields: {foo: {value: 12}}
    }
    let newVJ = Object.assign({}, state[0], {company: fakeSelectedCompany, published_journey_name: fakeData.published_journey_name.value, published_journey_identifier: fakeData.published_journey_identifier.value, custom_fields})
    expect(
      vjReducer(state, {
        type: 'EDIT_VEHICLEJOURNEY',
        data: fakeData,
        selectedCompany: fakeSelectedCompany
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

  it('should handle SELECT_SPECIFIC_STOP', () => {
    const newState = JSON.parse(JSON.stringify(state))
    let specific_stop_area_map = {1: 7, 3: 9}

    let specficStopPlaceModifiedVJAS = newState[0].vehicle_journey_at_stops
    specficStopPlaceModifiedVJAS[0].specific_stop_area_id = 7
    specficStopPlaceModifiedVJAS[2].specific_stop_area_id = 9

    let newVJ = Object.assign({}, newState[0], {vehicle_journey_at_stops: specficStopPlaceModifiedVJAS})
    expect(
      vjReducer(newState, {
        type: 'SELECT_SPECIFIC_STOP',
        specific_stop_area_map
      })
    ).toEqual([newVJ, newState[1]])
  })
})
