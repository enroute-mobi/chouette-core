import statusReducer from '../../../../app/packs/src/vehicle_journeys/reducers/filters'

let state = {}

describe('filters reducer', () => {
  const cleanInterval = {
    start:{
      hour: '00',
      minute: '00'
    },
    end:{
      hour: '23',
      minute: '59'
    }
  }
  beforeEach(() => {
    state = {
    toggleArrivals: false,
    query: {
      interval: {
        start:{
          hour: '11',
          minute: '11'
        },
        end:{
          hour: '22',
          minute: '22'
        }
      },
      journeyPattern: {},
      vehicleJourney: {},
      timetable: {},
      withoutSchedule: true,
      withoutTimeTable: true
    },
    queryString: ''
    }
  })

  it('should return the initial state', () => {
    expect(
      statusReducer(undefined, {})
    ).toEqual({})
  })

  it('should handle TOGGLE_ARRIVALS', () => {
    expect(
      statusReducer(state, {
        type: 'TOGGLE_ARRIVALS'
      })
    ).toEqual(Object.assign({}, state, {toggleArrivals: true}))
  })

  it('should handle RESET_FILTERS', () => {
    let cleanQuery = JSON.parse(JSON.stringify(state.query))
    cleanQuery.interval = cleanInterval
    expect(
      statusReducer(state, {
        type: 'RESET_FILTERS'
      })
    ).toEqual(Object.assign({}, state, {query: cleanQuery}))
  })

  it('should handle TOGGLE_WITHOUT_SCHEDULE', () => {
    let rslt = JSON.parse(JSON.stringify(state.query))
    rslt.withoutSchedule = false
    expect(
      statusReducer(state, {
        type: 'TOGGLE_WITHOUT_SCHEDULE'
      })
    ).toEqual(Object.assign({}, state, {query: rslt}))
  })

  it('should handle UPDATE_START_TIME_FILTER', () => {
    let val = 12
    let unit = 'minute'
    let rslt = JSON.parse(JSON.stringify(state.query))
    rslt.interval.start.minute = String(val)
    expect(
      statusReducer(state, {
        type: 'UPDATE_START_TIME_FILTER',
        val,
        unit
      })
    ).toEqual(Object.assign({}, state, {query: rslt}))
  })

  it('should handle UPDATE_START_TIME_FILTER and not make any update', () => {
    let val = 23
    let unit = 'hour'
    expect(
      statusReducer(state, {
        type: 'UPDATE_START_TIME_FILTER',
        val,
        unit
      })
    ).toEqual(state)
  })

  it('should handle UPDATE_END_TIME_FILTER', () => {
    let val = 12
    let unit = 'minute'
    let rslt = JSON.parse(JSON.stringify(state.query))
    rslt.interval.end.minute = String(val)
    expect(
      statusReducer(state, {
        type: 'UPDATE_END_TIME_FILTER',
        val,
        unit
      })
    ).toEqual(Object.assign({}, state, {query: rslt}))
  })

  it('should handle UPDATE_END_TIME_FILTER and not make any update', () => {
    let val = 1
    let unit = 'hour'
    expect(
      statusReducer(state, {
        type: 'UPDATE_END_TIME_FILTER',
        val,
        unit
      })
    ).toEqual(state)
  })

  it('should handle SELECT_TT_FILTER', () => {
    let newTimetable = {timetable : {id: 1}}
    let newQuery = Object.assign({}, state.query, newTimetable)
    expect(
      statusReducer(state, {
        type: 'SELECT_TT_FILTER',
        selectedItem: {id: 1}
      })
    ).toEqual(Object.assign({}, state, {query: newQuery}))
  })

  it('should handle SELECT_JP_FILTER', () => {
    let newJourneyPattern = {journeyPattern : {id: 1}}
    let newQuery = Object.assign({}, state.query, newJourneyPattern)
    expect(
      statusReducer(state, {
        type: 'SELECT_JP_FILTER',
        selectedItem: {id: 1}
      })
    ).toEqual(Object.assign({}, state, {query: newQuery}))
  })

  it('should handle CREATE_QUERY_STRING', () => {
    let strResult = [
      "q%5Bjourney_pattern_id_eq%5D=undefined",
      "&q%5Bobjectid_cont%5D=undefined",
      "&q%5Btime_tables_id_eq%5D=undefined",
      "&q%5Bvehicle_journey_at_stops_departure_time_gteq%5D=11%3A11",
      "&q%5Bvehicle_journey_at_stops_departure_time_lteq%5D=22%3A22",
      "&q%5Bvehicle_journey_without_departure_time%5D=true",
      "&q%5Bvehicle_journey_without_time_table%5D=true"
    ].join('')

    expect(
      statusReducer(state, {
        type: 'CREATE_QUERY_STRING',
      })
    ).toEqual(Object.assign({}, state, {queryString: strResult}))
  })
})
