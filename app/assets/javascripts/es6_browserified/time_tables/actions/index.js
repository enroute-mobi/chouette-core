const _ = require('lodash')

const actions = {
  strToArrayDayTypes: (str) =>{
    let weekDays = ['Di', 'Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa']
    return weekDays.map((day, i) => str.indexOf(day) !== -1)
  },
  arrayToStrDayTypes: (arr) => {
    let weekDays = ['Di', 'Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa']
    let str = []
    arr.map((dayActive, i) => {
      if(dayActive){
        str.push(weekDays[i])
      }
    })
    return str.join(',')
  },
  fetchingApi: () =>({
    type: 'FETCH_API'
  }),
  receiveErrors : (json) => ({
    type: "RECEIVE_ERRORS",
    json
  }),
  unavailableServer: () => ({
    type: 'UNAVAILABLE_SERVER'
  }),
  receiveMonth: (json) => ({
    type: 'RECEIVE_MONTH',
    json
  }),
  receiveTimeTables: (json) => ({
    type: 'RECEIVE_TIME_TABLES',
    json
  }),
  goToPreviousPage : (dispatch, pagination) => ({
    type: 'GO_TO_PREVIOUS_PAGE',
    dispatch,
    pagination,
    nextPage : false
  }),
  goToNextPage : (dispatch, pagination) => ({
    type: 'GO_TO_NEXT_PAGE',
    dispatch,
    pagination,
    nextPage : true
  }),
  changePage : (dispatch, val) => ({
    type: 'CHANGE_PAGE',
    dispatch,
    page: val
  }),
  updateDayTypes: (dayTypes) => ({
    type: 'UPDATE_DAY_TYPES',
    dayTypes
  }),
  updateCurrentMonthFromDaytypes: (dayTypes) => ({
    type: 'UPDATE_CURRENT_MONTH_FROM_DAYTYPES',
    dayTypes
  }),
  updateComment: (comment) => ({
    type: 'UPDATE_COMMENT',
    comment
  }),
  updateColor: (color) => ({
    type: 'UPDATE_COLOR',
    color
  }),
  select2Tags: (selectedTag) => ({
    type: 'UPDATE_SELECT_TAG',
    selectedItem: {
      id: selectedTag.id,
      name: selectedTag.name
    }
  }),
  unselect2Tags: (selectedTag) => ({
    type: 'UPDATE_UNSELECT_TAG',
    selectedItem: {
      id: selectedTag.id,
      name: selectedTag.name
    }
  }),
  deletePeriod: (index, dayTypes) => ({
    type: 'DELETE_PERIOD',
    index,
    dayTypes
  }),
  openAddPeriodForm: () => ({
    type: 'OPEN_ADD_PERIOD_FORM'
  }),
  openEditPeriodForm: (period, index) => ({
    type: 'OPEN_EDIT_PERIOD_FORM',
    period,
    index
  }),
  closePeriodForm: () => ({
    type: 'CLOSE_PERIOD_FORM'
  }),
  resetModalErrors: () => ({
    type: 'RESET_MODAL_ERRORS'
  }),
  updatePeriodForm: (val, group, selectType) => ({
    type: 'UPDATE_PERIOD_FORM',
    val,
    group,
    selectType
  }),
  validatePeriodForm: (modalProps, timeTablePeriods, metas, timeTableDates) => ({
    type: 'VALIDATE_PERIOD_FORM',
    modalProps,
    timeTablePeriods,
    metas,
    timeTableDates
  }),
  includeDateInPeriod: (index, dayTypes) => ({
    type: 'INCLUDE_DATE_IN_PERIOD',
    index,
    dayTypes
  }),
  excludeDateFromPeriod: (index, dayTypes) => ({
    type: 'EXCLUDE_DATE_FROM_PERIOD',
    index,
    dayTypes
  }),
  openConfirmModal : (callback) => ({
    type : 'OPEN_CONFIRM_MODAL',
    callback
  }),
  showErrorModal: (error) => ({
    type: 'OPEN_ERROR_MODAL',
    error
  }),
  closeModal : () => ({
    type : 'CLOSE_MODAL'
  }),
  monthName(strDate) {
    let monthList = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
    var date = new Date(strDate)
    return monthList[date.getMonth()]
  },
  getHumanDate(strDate, mLimit) {
    let origin = strDate.split('-')
    let D = origin[2]
    let M = actions.monthName(strDate).toLowerCase()
    let Y = origin[0]

    if(mLimit && M.length > mLimit) {
      M = M.substr(0, mLimit) + '.'
    }

    return (D + ' ' + M + ' ' + Y)
  },
  getLocaleDate(strDate) {
    let date = new Date(strDate)
    return date.toLocaleDateString()
  },

  updateSynthesis: (state, daytypes) => {
    let periods = state.time_table_periods

    let isInPeriod = function(d){
      let currentMonth = state.current_periode_range.split('-')
      let twodigitsDay = d.mday < 10 ? ('0' + d.mday) : d.mday
      let currentDate = new Date(currentMonth[0] + '-' + currentMonth[1] + '-' + twodigitsDay)

      // We compare periods & currentDate, to determine if it is included or not
      let testDate = false
      periods.map((p, i) => {
        if(p.deleted){
          return false
        }
        let begin = new Date(p.period_start)
        let end = new Date(p.period_end)

        if(testDate === false){
          if(currentDate >= begin && currentDate <= end) {
            testDate = true
            p.include_date = false
          }
        }
      })
      return testDate
    }

    let improvedCM = state.current_month.map((d, i) => {
      let bool = isInPeriod(state.current_month[i])
      return _.assign({}, state.current_month[i], {
        in_periods: bool,
        include_date: bool ? false : state.current_month[i].include_date,
        excluded_date: !bool ? false : state.current_month[i].excluded_date
      })
    })
    return improvedCM
  },
  checkConfirmModal: (event, callback, stateChanged, dispatch, metas, timetable) => {
    if(stateChanged){
      const error = actions.errorModalKey(timetable.time_table_periods, metas.day_types)
      if(error){
        return actions.showErrorModal(error)
      }else{
        return actions.openConfirmModal(callback)
      }
    }else{
      dispatch(actions.fetchingApi())
      return callback
    }
  },
  formatDate: (props) => {
    return props.year + '-' + props.month + '-' + props.day
  },
  checkErrorsInPeriods: (start, end, index, periods, days) => {
    let error = ''
    start = new Date(start)
    end = new Date(end)
    _.each(periods, (period, i) => {
      if(index !== i && !period.deleted){
        if((new Date(period.period_start) <= start && new Date(period.period_end) >= start) || (new Date(period.period_start) <= end && new Date(period.period_end) >= end) || (start >= new Date(period.period_start) && end <= new Date(period.period_end)) || (start <= new Date(period.period_start) && end >= new Date(period.period_end)))
        error = 'Les périodes ne peuvent pas se chevaucher'
      }
    })
    return error
  },
  checkErrorsInDates: (start, end, days) => {
    let error = ''
    start = new Date(start)
    end = new Date(end)

    _.each(days, ({date}) => {
      if (start <= new Date(date) && end >= new Date(date)) {
        error = 'Une période ne peut chevaucher une date dans un calendrier'
      }
    })
    return error
  },
  fetchTimeTables: (dispatch, nextPage) => {
    let urlJSON = window.location.pathname.split('/', 5).join('/')
    // console.log(nextPage)
    if(nextPage) {
      urlJSON += "/month.json?date=" + nextPage
    }else{
      urlJSON += ".json"
    }
    let hasError = false
    fetch(urlJSON, {
      credentials: 'same-origin',
    }).then(response => {
        if(response.status == 500) {
          hasError = true
        }
        return response.json()
      }).then((json) => {
        if(hasError == true) {
          dispatch(actions.unavailableServer())
        } else {
          if(nextPage){
            dispatch(actions.receiveMonth(json))
          }else{
            dispatch(actions.receiveTimeTables(json))
          }
        }
      })
  },
  submitTimetable: (dispatch, timetable, metas, next) => {
    dispatch(actions.fetchingApi())
    let strDayTypes = actions.arrayToStrDayTypes(metas.day_types)
    metas.day_types= strDayTypes
    let sentState = _.assign({}, timetable, metas)
    let urlJSON = window.location.pathname.split('/', 5).join('/')
    let hasError = false
    fetch(urlJSON + '.json', {
      credentials: 'same-origin',
      method: 'PATCH',
      contentType: 'application/json; charset=utf-8',
      Accept: 'application/json',
      body: JSON.stringify(sentState),
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    }).then(response => {
        if(!response.ok) {
          hasError = true
        }
        return response.json()
      }).then((json) => {
        if(hasError == true) {
          dispatch(actions.receiveErrors(json))
        } else {
          if(next) {
            dispatch(next)
          } else {
            dispatch(actions.receiveTimeTables(json))
          }
        }
      })
  },
  errorModalKey: (periods, dayTypes) => {
    const withoutPeriodsWithDaysTypes = _.reject(periods, 'deleted').length == 0 && _.some(dayTypes) && "withoutPeriodsWithDaysTypes"
    const withPeriodsWithoutDayTypes = _.reject(periods, 'deleted').length > 0 &&  _.every(dayTypes, dt => dt == false) && "withPeriodsWithoutDayTypes"

    return (withoutPeriodsWithDaysTypes || withPeriodsWithoutDayTypes) && (withoutPeriodsWithDaysTypes ? "withoutPeriodsWithDaysTypes" : "withPeriodsWithoutDayTypes")

  },
  errorModalMessage: (errorKey) => {
    switch (errorKey) {
      case "withoutPeriodsWithDaysTypes":
        return window.I18n.fr.time_tables.edit.error_modal.withoutPeriodsWithDaysTypes
      case "withPeriodsWithoutDayTypes":
        return window.I18n.fr.time_tables.edit.error_modal.withPeriodsWithoutDayTypes
      default:
        return errorKey

    }
  }
}

module.exports = actions
