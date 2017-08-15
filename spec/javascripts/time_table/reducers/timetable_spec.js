require('whatwg-fetch')
var timetableReducer = require('es6_browserified/time_tables/reducers/timetable')

let state = {}
const dispatch = function(){}
let arrDayTypes = [true, true, true, true, true, true, true]
let strDayTypes = 'LuMaMeJeVeSaDi'
let time_table_periods = [{"id":261,"period_start":"2017-02-23","period_end":"2017-03-05"},{"id":262,"period_start":"2017-03-15","period_end":"2017-03-25"},{"id":263,"period_start":"2017-04-04","period_end":"2017-04-14"},{"id":264,"period_start":"2017-04-24","period_end":"2017-05-04"},{"id":265,"period_start":"2017-05-14","period_end":"2017-05-24"}]
let current_periode_range = "2017-05-01"
let periode_range = ["2014-05-01","2014-06-01","2014-07-01","2014-08-01","2014-09-01","2014-10-01","2014-11-01","2014-12-01","2015-01-01","2015-02-01","2015-03-01","2015-04-01","2015-05-01","2015-06-01","2015-07-01","2015-08-01","2015-09-01","2015-10-01","2015-11-01","2015-12-01","2016-01-01","2016-02-01","2016-03-01","2016-04-01","2016-05-01","2016-06-01","2016-07-01","2016-08-01","2016-09-01","2016-10-01","2016-11-01","2016-12-01","2017-01-01","2017-02-01","2017-03-01","2017-04-01","2017-05-01","2017-06-01","2017-07-01","2017-08-01","2017-09-01","2017-10-01","2017-11-01","2017-12-01","2018-01-01","2018-02-01","2018-03-01","2018-04-01","2018-05-01","2018-06-01","2018-07-01","2018-08-01","2018-09-01","2018-10-01","2018-11-01","2018-12-01","2019-01-01","2019-02-01","2019-03-01","2019-04-01","2019-05-01","2019-06-01","2019-07-01","2019-08-01","2019-09-01","2019-10-01","2019-11-01","2019-12-01","2020-01-01","2020-02-01","2020-03-01","2020-04-01","2020-05-01"]
let current_month = [{"day":"lundi","date":"2017-05-01","wday":1,"wnumber":"18","mday":1,"include_date":false,"excluded_date":false},{"day":"mardi","date":"2017-05-02","wday":2,"wnumber":"18","mday":2,"include_date":false,"excluded_date":false},{"day":"mercredi","date":"2017-05-03","wday":3,"wnumber":"18","mday":3,"include_date":false,"excluded_date":false},{"day":"jeudi","date":"2017-05-04","wday":4,"wnumber":"18","mday":4,"include_date":false,"excluded_date":false},{"day":"vendredi","date":"2017-05-05","wday":5,"wnumber":"18","mday":5,"include_date":false,"excluded_date":false},{"day":"samedi","date":"2017-05-06","wday":6,"wnumber":"18","mday":6,"include_date":false,"excluded_date":false},{"day":"dimanche","date":"2017-05-07","wday":0,"wnumber":"18","mday":7,"include_date":false,"excluded_date":false},{"day":"lundi","date":"2017-05-08","wday":1,"wnumber":"19","mday":8,"include_date":false,"excluded_date":false},{"day":"mardi","date":"2017-05-09","wday":2,"wnumber":"19","mday":9,"include_date":false,"excluded_date":false},{"day":"mercredi","date":"2017-05-10","wday":3,"wnumber":"19","mday":10,"include_date":false,"excluded_date":false},{"day":"jeudi","date":"2017-05-11","wday":4,"wnumber":"19","mday":11,"include_date":false,"excluded_date":false},{"day":"vendredi","date":"2017-05-12","wday":5,"wnumber":"19","mday":12,"include_date":false,"excluded_date":false},{"day":"samedi","date":"2017-05-13","wday":6,"wnumber":"19","mday":13,"include_date":false,"excluded_date":false},{"day":"dimanche","date":"2017-05-14","wday":0,"wnumber":"19","mday":14,"include_date":false,"excluded_date":false},{"day":"lundi","date":"2017-05-15","wday":1,"wnumber":"20","mday":15,"include_date":false,"excluded_date":false},{"day":"mardi","date":"2017-05-16","wday":2,"wnumber":"20","mday":16,"include_date":false,"excluded_date":false},{"day":"mercredi","date":"2017-05-17","wday":3,"wnumber":"20","mday":17,"include_date":false,"excluded_date":false},{"day":"jeudi","date":"2017-05-18","wday":4,"wnumber":"20","mday":18,"include_date":false,"excluded_date":false},{"day":"vendredi","date":"2017-05-19","wday":5,"wnumber":"20","mday":19,"include_date":false,"excluded_date":false},{"day":"samedi","date":"2017-05-20","wday":6,"wnumber":"20","mday":20,"include_date":false,"excluded_date":false},{"day":"dimanche","date":"2017-05-21","wday":0,"wnumber":"20","mday":21,"include_date":false,"excluded_date":false},{"day":"lundi","date":"2017-05-22","wday":1,"wnumber":"21","mday":22,"include_date":false,"excluded_date":false},{"day":"mardi","date":"2017-05-23","wday":2,"wnumber":"21","mday":23,"include_date":false,"excluded_date":false},{"day":"mercredi","date":"2017-05-24","wday":3,"wnumber":"21","mday":24,"include_date":false,"excluded_date":false},{"day":"jeudi","date":"2017-05-25","wday":4,"wnumber":"21","mday":25,"include_date":false,"excluded_date":false},{"day":"vendredi","date":"2017-05-26","wday":5,"wnumber":"21","mday":26,"include_date":false,"excluded_date":false},{"day":"samedi","date":"2017-05-27","wday":6,"wnumber":"21","mday":27,"include_date":false,"excluded_date":false},{"day":"dimanche","date":"2017-05-28","wday":0,"wnumber":"21","mday":28,"include_date":false,"excluded_date":false},{"day":"lundi","date":"2017-05-29","wday":1,"wnumber":"22","mday":29,"include_date":false,"excluded_date":false},{"day":"mardi","date":"2017-05-30","wday":2,"wnumber":"22","mday":30,"include_date":false,"excluded_date":false},{"day":"mercredi","date":"2017-05-31","wday":3,"wnumber":"22","mday":31,"include_date":false,"excluded_date":false}]

let newCurrentMonth = [{"day":"lundi","date":"2017-05-01","wday":1,"wnumber":"18","mday":1,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"mardi","date":"2017-05-02","wday":2,"wnumber":"18","mday":2,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"mercredi","date":"2017-05-03","wday":3,"wnumber":"18","mday":3,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"jeudi","date":"2017-05-04","wday":4,"wnumber":"18","mday":4,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"vendredi","date":"2017-05-05","wday":5,"wnumber":"18","mday":5,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"samedi","date":"2017-05-06","wday":6,"wnumber":"18","mday":6,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"dimanche","date":"2017-05-07","wday":0,"wnumber":"18","mday":7,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"lundi","date":"2017-05-08","wday":1,"wnumber":"19","mday":8,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"mardi","date":"2017-05-09","wday":2,"wnumber":"19","mday":9,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"mercredi","date":"2017-05-10","wday":3,"wnumber":"19","mday":10,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"jeudi","date":"2017-05-11","wday":4,"wnumber":"19","mday":11,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"vendredi","date":"2017-05-12","wday":5,"wnumber":"19","mday":12,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"samedi","date":"2017-05-13","wday":6,"wnumber":"19","mday":13,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"dimanche","date":"2017-05-14","wday":0,"wnumber":"19","mday":14,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"lundi","date":"2017-05-15","wday":1,"wnumber":"20","mday":15,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"mardi","date":"2017-05-16","wday":2,"wnumber":"20","mday":16,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"mercredi","date":"2017-05-17","wday":3,"wnumber":"20","mday":17,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"jeudi","date":"2017-05-18","wday":4,"wnumber":"20","mday":18,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"vendredi","date":"2017-05-19","wday":5,"wnumber":"20","mday":19,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"samedi","date":"2017-05-20","wday":6,"wnumber":"20","mday":20,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"dimanche","date":"2017-05-21","wday":0,"wnumber":"20","mday":21,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"lundi","date":"2017-05-22","wday":1,"wnumber":"21","mday":22,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"mardi","date":"2017-05-23","wday":2,"wnumber":"21","mday":23,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"mercredi","date":"2017-05-24","wday":3,"wnumber":"21","mday":24,"include_date":false,"excluded_date":false,"in_periods":true},{"day":"jeudi","date":"2017-05-25","wday":4,"wnumber":"21","mday":25,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"vendredi","date":"2017-05-26","wday":5,"wnumber":"21","mday":26,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"samedi","date":"2017-05-27","wday":6,"wnumber":"21","mday":27,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"dimanche","date":"2017-05-28","wday":0,"wnumber":"21","mday":28,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"lundi","date":"2017-05-29","wday":1,"wnumber":"22","mday":29,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"mardi","date":"2017-05-30","wday":2,"wnumber":"22","mday":30,"include_date":false,"excluded_date":false,"in_periods":false},{"day":"mercredi","date":"2017-05-31","wday":3,"wnumber":"22","mday":31,"include_date":false,"excluded_date":false,"in_periods":false}]

let time_table_dates = []

let json = {
  current_month: current_month,
  current_periode_range: current_periode_range,
  periode_range: periode_range,
  time_table_periods: time_table_periods,
  day_types: strDayTypes,
  time_table_dates: time_table_dates
}

describe('timetable reducer with empty state', () => {
  beforeEach(() => {
    state = {
      current_month: [],
      current_periode_range: "",
      periode_range: [],
      time_table_periods: [],
      time_table_dates: []
    }
  })

  it('should return the initial state', () => {
    expect(
      timetableReducer(undefined, {})
    ).toEqual({})
  })

  it('should handle RECEIVE_TIME_TABLES', () => {
    let newState = {
      current_month: newCurrentMonth,
      current_periode_range: current_periode_range,
      periode_range: periode_range,
      time_table_periods: time_table_periods,
      time_table_dates: time_table_dates
    }
    expect(
      timetableReducer(state, {
        type: 'RECEIVE_TIME_TABLES',
        json
      })
    ).toEqual(newState)
  })
})

describe('timetable reducer with filled state', () => {
  beforeEach(() => {
    state = {
      current_month: newCurrentMonth,
      current_periode_range: current_periode_range,
      periode_range: periode_range,
      time_table_periods: time_table_periods,
      time_table_dates: time_table_dates
    }
  })

  it('should handle RECEIVE_MONTH', () => {
    expect(
      timetableReducer(state, {
        type: 'RECEIVE_MONTH',
        json: {
          days: current_month,
          day_types: strDayTypes
        }
      })
    ).toEqual(state)
  })


  it('should handle GO_TO_PREVIOUS_PAGE', () => {
    let pagination = {
      periode_range: periode_range,
      currentPage: current_periode_range
    }
    expect(
      timetableReducer(state, {
        type: 'GO_TO_PREVIOUS_PAGE',
        dispatch,
        pagination,
        nextPage: false
      })
    ).toEqual(Object.assign({}, state, {current_periode_range: '2017-04-01'}))
  })

  it('should handle GO_TO_NEXT_PAGE', () => {
    let pagination = {
      periode_range: periode_range,
      currentPage: current_periode_range
    }
    expect(
      timetableReducer(state, {
        type: 'GO_TO_NEXT_PAGE',
        dispatch,
        pagination,
        nextPage: true
      })
    ).toEqual(Object.assign({}, state, {current_periode_range: '2017-06-01'}))
  })

  it('should handle CHANGE_PAGE', () => {
    const actions = {
      fetchTimeTables: function(){}
    }
    let newPage = '2017-05-01'
    expect(
      timetableReducer(state, {
        type: 'CHANGE_PAGE',
        dispatch,
        page: newPage
      })
    ).toEqual(Object.assign({}, state, {current_periode_range: newPage}))
  })

  it('should handle DELETE_PERIOD', () => {
    state.time_table_periods[0].deleted = true
    expect(
      timetableReducer(state, {
        type: 'DELETE_PERIOD',
        index: 0,
        dayTypes: arrDayTypes
      })
    ).toEqual(state)
  })

  it('should handle INCLUDE_DATE_IN_PERIOD and add in_day if TT doesnt have it', () => {
    let newDates = state.time_table_dates.concat({date: "2017-05-05", in_out: true})
    let newState = Object.assign({}, state, {time_table_dates: newDates})
    state.current_month[4].include_date = true
    expect(
      timetableReducer(state, {
        type: 'INCLUDE_DATE_IN_PERIOD',
        index: 4,
        dayTypes: arrDayTypes,
        date: "2017-05-05"
      })
    ).toEqual(newState)
  })

  it('should handle INCLUDE_DATE_IN_PERIOD and remove in_day if TT has it', () => {
    state.current_month[4].include_date = true
    state.time_table_dates.push({date: "2017-05-05", in_out: true})
    let newState = Object.assign({}, state, {time_table_dates: []})
    expect(
      timetableReducer(state, {
        type: 'INCLUDE_DATE_IN_PERIOD',
        index: 4,
        dayTypes: arrDayTypes,
        date: "2017-05-05"
      })
    ).toEqual(newState)
  })

  it('should handle EXCLUDE_DATE_FROM_PERIOD and add out_day if TT doesnt have it', () => {
    let newDates = state.time_table_dates.concat({date: "2017-05-01", in_out: false})
    let newState = Object.assign({}, state, {time_table_dates: newDates})
    state.current_month[0].excluded_date = true
    expect(
      timetableReducer(state, {
        type: 'EXCLUDE_DATE_FROM_PERIOD',
        index: 0,
        dayTypes: arrDayTypes,
        date: "2017-05-01"
      })
    ).toEqual(newState)
  })

  it('should handle EXCLUDE_DATE_FROM_PERIOD and remove out_day if TT has it', () => {
    state.time_table_dates = [{date: "2017-05-01", in_out: false}]
    state.current_month[0].excluded_date = true
    let newState = Object.assign({}, state, {time_table_dates: []})
    expect(
      timetableReducer(state, {
        type: 'EXCLUDE_DATE_FROM_PERIOD',
        index: 0,
        dayTypes: arrDayTypes,
        date: "2017-05-01"
      })
    ).toEqual(newState)
  })

  it('should handle VALIDATE_PERIOD_FORM and add period if modalProps index = false', () => {
    let newPeriods = state.time_table_periods.concat({"period_start": "2018-05-15", "period_end": "2018-05-24"})
    let newState = Object.assign({}, state, {time_table_periods: newPeriods})
    let modalProps = {
      active: false,
      begin: {
        day: '15',
        month: '05',
        year: '2018'
      },
      end: {
        day: '24',
        month: '05',
        year: '2018'
      },
      error: '',
      index: false
    }
    expect(
      timetableReducer(state, {
        type: 'VALIDATE_PERIOD_FORM',
        modalProps: modalProps,
        timeTablePeriods: state.time_table_periods,
        metas: {
          day_types: arrDayTypes
        },
        timetableInDates: state.time_table_dates.filter(d => d.in_out == true)
      })
    ).toEqual(newState)
  })
})
