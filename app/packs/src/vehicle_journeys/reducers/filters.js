import _ from 'lodash'
import actions from '../actions'
let newQuery, newInterval

export default function  filters(state = {}, action) {
  switch (action.type) {
    case 'RESET_FILTERS':
      let interval = {
        start:{
          hour: '00',
          minute: '00'
        },
        end:{
          hour: '23',
          minute: '59'
        }
      }
      newQuery = _.assign({}, state.query, {interval: interval, journeyPattern: {}, vehicleJourney: {}, timetable: {}, withoutSchedule: true, withoutTimeTable: true })
      return _.assign({}, state, {query: newQuery, queryString: ''})
    case 'TOGGLE_WITHOUT_SCHEDULE':
      newQuery = _.assign({}, state.query, {withoutSchedule: !state.query.withoutSchedule})
      return _.assign({}, state, {query: newQuery})
    case 'TOGGLE_WITHOUT_TIMETABLE':
      newQuery = _.assign({}, state.query, {withoutTimeTable: !state.query.withoutTimeTable})
      return _.assign({}, state, {query: newQuery})
    case 'UPDATE_END_TIME_FILTER':
      newInterval = JSON.parse(JSON.stringify(state.query.interval))
      newInterval.end[action.unit] = actions.pad(action.val, action.unit)
      if(parseInt(newInterval.start.hour + newInterval.start.minute) < parseInt(newInterval.end.hour + newInterval.end.minute)){
        newQuery = _.assign({}, state.query, {interval: newInterval})
        return _.assign({}, state, {query: newQuery})
      }else{
        return state
      }
    case 'UPDATE_START_TIME_FILTER':
      newInterval = JSON.parse(JSON.stringify(state.query.interval))
      newInterval.start[action.unit] = actions.pad(action.val, action.unit)
      if(parseInt(newInterval.start.hour + newInterval.start.minute) < parseInt(newInterval.end.hour + newInterval.end.minute)){
        newQuery = _.assign({}, state.query, {interval: newInterval})
        return _.assign({}, state, {query: newQuery})
      }else{
        return state
      }
    case 'SELECT_TT_FILTER':
      newQuery = _.assign({}, state.query, {timetable : action.selectedItem})
      return _.assign({}, state, {query: newQuery})
    case 'SELECT_JP_FILTER':
      newQuery = _.assign({}, state.query, {journeyPattern : action.selectedItem})
      return _.assign({}, state, {query: newQuery})
    case 'SELECT_VJ_FILTER':
      newQuery = _.assign({}, state.query, {vehicleJourney : action.selectedItem})
      return _.assign({}, state, {query: newQuery})
    case 'TOGGLE_ARRIVALS':
      return _.assign({}, state, {toggleArrivals: !state.toggleArrivals})
    case 'QUERY_FILTER_VEHICLEJOURNEYS':
      actions.fetchVehicleJourneys(action.dispatch, undefined, undefined, state.queryString)
      return state
    case 'CREATE_QUERY_STRING':
      let params = {
        'search[journey_pattern_id]': state.query.journeyPattern.id || undefined,
        'search[text]': state.query.vehicleJourney.objectid || undefined,
        'search[time_table_id]': state.query.timetable.id || undefined,
        'search[departure_time_start]': (state.query.interval.start.hour + ':' + state.query.interval.start.minute),
        'search[departure_time_end]': (state.query.interval.end.hour + ':' + state.query.interval.end.minute),
        'search[departure_time_allow_empty]': state.query.withoutSchedule,
        'search[with_time_table]': state.query.withoutTimeTable
      }
      let queryString = actions.encodeParams(params)
      return _.assign({}, state, {queryString: queryString})
    default:
      return state
  }
}
