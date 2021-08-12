import assign from 'lodash/assign'
import reject from 'lodash/reject'
import sortBy from 'lodash/sortBy'
import reduce from 'lodash/reduce'
import actions from '../actions'

export default function timetable(state = {}, action) {
  let newState, newPeriods, newDates, newCM
  switch (action.type) {
    case 'RECEIVE_TIME_TABLES':
      let fetchedState = assign({}, state, {
        current_month: action.json.current_month,
        current_periode_range: action.json.current_periode_range,
        periode_range: action.json.periode_range,
        time_table_periods: action.json.time_table_periods,
        time_table_dates: sortBy(action.json.time_table_dates, ['date'])
      })
      return assign({}, fetchedState, {current_month: actions.updateSynthesis(fetchedState)})
    case 'RECEIVE_MONTH':
      newState = assign({}, state, {
        current_month: action.json.days
      })
      return assign({}, newState, {current_month: actions.updateSynthesis(newState)})
    case 'GO_TO_PREVIOUS_PAGE':
    case 'GO_TO_NEXT_PAGE':
      let nextPage = action.nextPage ? 1 : -1
      let newPage = action.pagination.periode_range[action.pagination.periode_range.indexOf(action.pagination.currentPage) + nextPage]
      $('#ConfirmModal').modal('hide')
      actions.fetchTimeTables(action.dispatch, newPage)
      return assign({}, state, {current_periode_range: newPage})
    case 'CHANGE_PAGE':
      $('#ConfirmModal').modal('hide')
      actions.fetchTimeTables(action.dispatch, action.page)
      return assign({}, state, {current_periode_range: action.page})
    case 'DELETE_PERIOD':
      newPeriods = state.time_table_periods.map((period, i) =>{
        if(i == action.index){
          period.deleted = true
        }
        return period
      })
      let deletedPeriod = Array.of(state.time_table_periods[action.index])
      newDates = reject(state.time_table_dates, d => actions.isInPeriod(deletedPeriod, d.date) && !d.in_out)
      newState = assign({}, state, {time_table_periods : newPeriods, time_table_dates: newDates})
      return assign({}, newState, { current_month: actions.updateSynthesis(newState)})
    case 'ADD_INCLUDED_DATE':
      newDates = state.time_table_dates.concat({date: action.date, in_out: true})
      newCM = state.current_month.map((d, i) => {
        if (i == action.index) d.include_date = true
        return d
      })
      return assign({}, state, {current_month: newCM, time_table_dates: newDates})
    case 'REMOVE_INCLUDED_DATE':
      newDates = reject(state.time_table_dates, ['date', action.date])
      newCM = state.current_month.map((d, i) => {
        if (i == action.index) d.include_date = false
        return d
      })
      return assign({}, state, {current_month: newCM, time_table_dates: newDates})
    case 'ADD_EXCLUDED_DATE':
      newDates = state.time_table_dates.concat({date: action.date, in_out: false})
      newCM = state.current_month.map((d, i) => {
        if (i == action.index) d.excluded_date = true
        return d
      })
      return assign({}, state, {current_month: newCM, time_table_dates: newDates})
    case 'REMOVE_EXCLUDED_DATE':
      newDates = reject(state.time_table_dates, ['date', action.date])
      newCM = state.current_month.map((d, i) => {
        if (i == action.index) d.excluded_date = false
        return d
      })
      return assign({}, state, {current_month: newCM, time_table_dates: newDates})
    case 'UPDATE_DAY_TYPES':
      // We get the week days of the activated day types to reject the out_dates that that are out of newDayTypes
      let weekDays = reduce(action.dayTypes, (array, dt, i) => {
        if (dt) array.push(i)
        return array
      }, [])

      newDates =  reject(state.time_table_dates, (d) => {
        let weekDay = new Date(d.date).getDay()

        if (d.in_out) {
          return actions.isInPeriod(state.time_table_periods, d.date) && weekDays.includes(weekDay)
        } else {
          return !weekDays.includes(weekDay)
        }
      })
      return assign({}, state, {time_table_dates: newDates})
    case 'UPDATE_CURRENT_MONTH_FROM_DAYTYPES':
      return assign({}, state, {current_month: actions.updateSynthesis(state)})
    case 'VALIDATE_PERIOD_FORM':
      if (action.error != '') return state

      let period_start = actions.formatDate(action.modalProps.begin)
      let period_end = actions.formatDate(action.modalProps.end)

      newPeriods = JSON.parse(JSON.stringify(action.timeTablePeriods))

      if (action.modalProps.index !== false){
        let updatedPeriod = newPeriods[action.modalProps.index]
        updatedPeriod.period_start = period_start
        updatedPeriod.period_end = period_end
        newDates = reject(state.time_table_dates, d => actions.isInPeriod(newPeriods, d.date) && !d.in_out)
      }else{
        let newPeriod = {
          period_start: period_start,
          period_end: period_end
        }
        newPeriods.push(newPeriod)
      }

      newDates = newDates || state.time_table_dates
      newState =assign({}, state, {time_table_periods: newPeriods, time_table_dates: newDates})
      return assign({}, newState, {current_month: actions.updateSynthesis(newState)})
    default:
      return state
  }
}
