var Promise = require('promise-polyfill')

// To add to window
if (!window.Promise) {
  window.Promise = Promise;
}
var batchActions = require('../batch').batchActions

const actions = {
  enterEditMode: () => ({
    type: "ENTER_EDIT_MODE"
  }),
  exitEditMode: () => ({
    type: "EXIT_EDIT_MODE"
  }),
  receiveVehicleJourneys : (json) => ({
    type: "RECEIVE_VEHICLE_JOURNEYS",
    json
  }),
  receiveErrors : (json) => ({
    type: "RECEIVE_ERRORS",
    json
  }),
  fetchingApi: () =>({
      type: 'FETCH_API'
  }),
  unavailableServer : () => ({
    type: 'UNAVAILABLE_SERVER'
  }),
  goToPreviousPage : (dispatch, pagination, queryString) => ({
    type: 'GO_TO_PREVIOUS_PAGE',
    dispatch,
    pagination,
    nextPage : false,
    queryString
  }),
  goToNextPage : (dispatch, pagination, queryString) => ({
    type: 'GO_TO_NEXT_PAGE',
    dispatch,
    pagination,
    nextPage : true,
    queryString
  }),
  checkConfirmModal : (event, callback, stateChanged, dispatch) => {
    if(stateChanged === true){
      return actions.openConfirmModal(callback)
    }else{
      dispatch(actions.fetchingApi())
      return callback
    }
  },
  openCreateModal : () => ({
    type : 'CREATE_VEHICLEJOURNEY_MODAL'
  }),
  selectJPCreateModal : (selectedJP) => ({
    type : 'SELECT_JP_CREATE_MODAL',
    selectedItem: {
      id: selectedJP.id,
      objectid: selectedJP.object_id,
      name: selectedJP.name,
      published_name: selectedJP.published_name,
      stop_areas: selectedJP.stop_area_short_descriptions
    }
  }),
  openEditModal : (vehicleJourney) => ({
    type : 'EDIT_VEHICLEJOURNEY_MODAL',
    vehicleJourney
  }),
  openNotesEditModal : (vehicleJourney) => ({
    type : 'EDIT_NOTES_VEHICLEJOURNEY_MODAL',
    vehicleJourney
  }),
  toggleFootnoteModal : (footnote, isShown) => ({
    type: 'TOGGLE_FOOTNOTE_MODAL',
    footnote,
    isShown
  }),
  openCalendarsEditModal : (vehicleJourneys) => ({
    type : 'EDIT_CALENDARS_VEHICLEJOURNEY_MODAL',
    vehicleJourneys
  }),
  selectTTCalendarsModal: (selectedTT) =>({
    type: 'SELECT_TT_CALENDAR_MODAL',
    selectedItem:{
      id: selectedTT.id,
      comment: selectedTT.comment,
      objectid: selectedTT.objectid
    }
  }),
  addSelectedTimetable: () => ({
    type: 'ADD_SELECTED_TIMETABLE'
  }),
  deleteCalendarModal : (timetable) => ({
    type : 'DELETE_CALENDAR_MODAL',
    timetable
  }),
  editVehicleJourneyTimetables : (vehicleJourneys, timetables) => ({
    type: 'EDIT_VEHICLEJOURNEYS_TIMETABLES',
    vehicleJourneys,
    timetables
  }),
  openShiftModal : () => ({
    type : 'SHIFT_VEHICLEJOURNEY_MODAL'
  }),
  openDuplicateModal : () => ({
    type : 'DUPLICATE_VEHICLEJOURNEY_MODAL'
  }),
  selectVehicleJourney : (index) => ({
    type : 'SELECT_VEHICLEJOURNEY',
    index
  }),
  cancelSelection : () => ({
    type: 'CANCEL_SELECTION'
  }),
  addVehicleJourney : (data, selectedJourneyPattern, stopPointsList, selectedCompany) => ({
    type: 'ADD_VEHICLEJOURNEY',
    data,
    selectedJourneyPattern,
    stopPointsList,
    selectedCompany
  }),
  select2Company: (selectedCompany) => ({
    type: 'SELECT_CP_EDIT_MODAL',
    selectedItem: {
      id: selectedCompany.id,
      name: selectedCompany.name,
      objectid: selectedCompany.objectid
    }
  }),
  editVehicleJourney : (data, selectedCompany) => ({
    type: 'EDIT_VEHICLEJOURNEY',
    data,
    selectedCompany
  }),
  editVehicleJourneyNotes : (footnotes) => ({
    type: 'EDIT_VEHICLEJOURNEY_NOTES',
    footnotes
  }),
  shiftVehicleJourney : (data) => ({
    type: 'SHIFT_VEHICLEJOURNEY',
    data
  }),
  duplicateVehicleJourney : (data, departureDelta) => ({
    type: 'DUPLICATE_VEHICLEJOURNEY',
    data,
    departureDelta
  }),
  deleteVehicleJourneys : () => ({
    type: 'DELETE_VEHICLEJOURNEYS'
  }),
  openConfirmModal : (callback) => ({
    type : 'OPEN_CONFIRM_MODAL',
    callback
  }),
  closeModal : () => ({
    type : 'CLOSE_MODAL'
  }),
  resetValidation: (target) => {
    $(target).parent().removeClass('has-error').children('.help-block').remove()
  },
  validateFields : (fields) => {
    const test = []

    Object.keys(fields).map(function(key) {
      test.push(fields[key].validity.valid)
    })
    if(test.indexOf(false) >= 0) {
      // Form is invalid
      test.map(function(item, i) {
        if(item == false) {
          const k = Object.keys(fields)[i]
          $(fields[k]).parent().addClass('has-error').children('.help-block').remove()
          $(fields[k]).parent().append("<span class='small help-block'>" + fields[k].validationMessage + "</span>")
        }
      })
      return false
    } else {
      // Form is valid
      return true
    }
  },
  toggleArrivals : () => ({
    type: 'TOGGLE_ARRIVALS',
  }),
  updateTime : (val, subIndex, index, timeUnit, isDeparture, isArrivalsToggled) => ({
    type: 'UPDATE_TIME',
    val,
    subIndex,
    index,
    timeUnit,
    isDeparture,
    isArrivalsToggled
  }),
  resetStateFilters: () => ({
    type: 'RESET_FILTERS'
  }),
  toggleWithoutSchedule: () => ({
    type: 'TOGGLE_WITHOUT_SCHEDULE'
  }),
  toggleWithoutTimeTable: () => ({
    type: 'TOGGLE_WITHOUT_TIMETABLE'
  }),
  updateStartTimeFilter: (val, unit) => ({
    type: 'UPDATE_START_TIME_FILTER',
    val,
    unit
  }),
  updateEndTimeFilter: (val, unit) => ({
    type: 'UPDATE_END_TIME_FILTER',
    val,
    unit
  }),
  filterSelect2Timetable: (selectedTT) =>({
    type: 'SELECT_TT_FILTER',
    selectedItem:{
      id: selectedTT.id,
      comment: selectedTT.comment,
      objectid: selectedTT.objectid
    }
  }),
  filterSelect2JourneyPattern: (selectedJP) => ({
    type : 'SELECT_JP_FILTER',
    selectedItem: {
      id: selectedJP.id,
      objectid: selectedJP.object_id,
      name: selectedJP.name,
      published_name: selectedJP.published_name
    }
  }),
  filterSelect2VehicleJourney: (selectedVJ) => ({
    type : 'SELECT_VJ_FILTER',
    selectedItem: {
      objectid: selectedVJ.objectid
    }
  }),
  createQueryString: () => ({
    type: 'CREATE_QUERY_STRING'
  }),
  resetPagination: () => ({
    type: 'RESET_PAGINATION'
  }),
  queryFilterVehicleJourneys: (dispatch) => ({
    type: 'QUERY_FILTER_VEHICLEJOURNEYS',
    dispatch
  }),
  resetFilters: (dispatch) => (
    batchActions([
      actions.resetStateFilters(),
      actions.resetPagination(),
      actions.queryFilterVehicleJourneys(dispatch)
    ])
  ),
  filterQuery: (dispatch) => (
    batchActions([
      actions.createQueryString(),
      actions.resetPagination(),
      actions.queryFilterVehicleJourneys(dispatch)
    ])
  ),
  updateTotalCount: (diff) => ({
    type: 'UPDATE_TOTAL_COUNT',
    diff
  }),
  receiveTotalCount: (total) => ({
    type: 'RECEIVE_TOTAL_COUNT',
    total
  }),
  humanOID : (oid) => {
    var a = oid.split(':')
    return a[a.length - 1]
  },
  fetchVehicleJourneys : (dispatch, currentPage, nextPage, queryString) => {
    if(currentPage == undefined){
      currentPage = 1
    }
    let vehicleJourneys = []
    let page
    switch (nextPage) {
      case true:
        page = currentPage + 1
        break
      case false:
        if(currentPage > 1){
          page = currentPage - 1
        }
        break
      default:
        page = currentPage
        break
    }
    let str = ".json"
    let sep = '?'
    if(page > 1){
      str = '.json?page=' + page.toString()
      sep = '&'
    }
    let urlJSON = window.location.pathname + str
    if (queryString){
      urlJSON = urlJSON + sep + queryString
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
          let val
          for (val of json.vehicle_journeys){
            var timeTables = []
            let tt
            for (tt of val.time_tables){
              timeTables.push({
                objectid: tt.objectid,
                comment: tt.comment,
                id: tt.id,
                color: tt.color
              })
            }
            let vjasWithDelta = val.vehicle_journey_at_stops.map((vjas, i) => {
              actions.fillEmptyFields(vjas)
              return actions.getDelta(vjas)
            })
            vehicleJourneys.push({
              journey_pattern: val.journey_pattern,
              published_journey_name: val.published_journey_name,
              objectid: val.objectid,
              footnotes: val.footnotes,
              time_tables: timeTables,
              vehicle_journey_at_stops: vjasWithDelta,
              deletable: false,
              selected: false,
              published_journey_name: val.published_journey_name || 'non renseigné',
              published_journey_identifier: val.published_journey_identifier || 'non renseigné',
              company: val.company || 'non renseigné',
              transport_mode: val.route.line.transport_mode || 'undefined',
              transport_submode: val.route.line.transport_submode || 'undefined'
            })
          }
          window.currentItemsLength = vehicleJourneys.length
          dispatch(actions.receiveVehicleJourneys(vehicleJourneys))
          dispatch(actions.receiveTotalCount(json.total))
        }
      })
  },
  submitVehicleJourneys : (dispatch, state, next) => {
    dispatch(actions.fetchingApi())
    let urlJSON = window.location.pathname + "_collection.json"
    let hasError = false
    fetch(urlJSON, {
      credentials: 'same-origin',
      method: 'PATCH',
      contentType: 'application/json; charset=utf-8',
      Accept: 'application/json',
      body: JSON.stringify(state),
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
            if(json.length != window.currentItemsLength){
              dispatch(actions.updateTotalCount(window.currentItemsLength - json.length))
            }
            window.currentItemsLength = json.length
            dispatch(actions.receiveVehicleJourneys(json))
          }
        }
      })
  },
  // VJAS HELPERS
  getSelected: (vj) => {
    return vj.filter((obj) =>{
      return obj.selected
    })
  },
  simplePad: (d) => {
    if(d.toString().length == 1){
      return (d < 10) ? '0' + d.toString() : d.toString();
    }else{
      return d.toString()
    }
  },
  pad: (d, timeUnit) => {
    let val = d.toString()
    if(d.toString().length == 1){
      val = (d < 10) ? '0' + d.toString() : d.toString();
    }
    if(val.length > 2){
      val = val.substr(1)
    }
    if(timeUnit == 'minute' && parseInt(val) > 59){
      val = '59'
    }
    if(timeUnit == 'hour' && parseInt(val) > 23){
      val = '23'
    }
    return val
  },
  encodeParams: (params) => {
    let esc = encodeURIComponent
    let queryString = Object.keys(params).map((k) => esc(k) + '=' + esc(params[k])).join('&')
    return queryString
  },
  fillEmptyFields: (vjas) => {
    if (vjas.departure_time.hour == null) vjas.departure_time.hour = '00'
    if (vjas.departure_time.minute == null) vjas.departure_time.minute = '00'
    if (vjas.arrival_time.hour == null) vjas.arrival_time.hour = '00'
    if (vjas.arrival_time.minute == null) vjas.arrival_time.minute = '00'
    return vjas
  },
  getDuplicateDelta: (original, newDeparture) => {
    if (original.departure_time.hour != '' && original.departure_time.minute != '' && newDeparture.departure_time.hour != '' && newDeparture.departure_time.minute != ''){
      return  (parseInt(newDeparture.departure_time.hour) - parseInt(original.departure_time.hour)) * 60 + (parseInt(newDeparture.departure_time.minute) - parseInt(original.departure_time.minute))
    }
    return 0
  },
  getDelta: (vjas) => {
    let delta = 0
    if (vjas.departure_time.hour != '' && vjas.departure_time.minute != '' && vjas.arrival_time.hour != '' && vjas.departure_time.minute != ''){
      delta = (parseInt(vjas.departure_time.hour) - parseInt(vjas.arrival_time.hour)) * 60 + (parseInt(vjas.departure_time.minute) - parseInt(vjas.arrival_time.minute))
    }
    vjas.delta = delta
    return vjas
  },
  checkSchedules: (schedule) => {
    let hours = 0
    let minutes = 0
    if (parseInt(schedule.departure_time.minute) > 59){
      hours = Math.floor(parseInt(schedule.departure_time.minute) / 60)
      minutes = parseInt(schedule.departure_time.minute) % 60
      schedule.departure_time.minute = actions.simplePad(minutes, 'minute')
      schedule.departure_time.hour = parseInt(schedule.departure_time.hour) + hours
    }
    if (parseInt(schedule.arrival_time.minute) > 59){
      hours = Math.floor(parseInt(schedule.arrival_time.minute) / 60)
      minutes = parseInt(schedule.arrival_time.minute) % 60
      schedule.arrival_time.minute = actions.simplePad(minutes, 'minute')
      schedule.arrival_time.hour = parseInt(schedule.arrival_time.hour) + hours
    }
    if (parseInt(schedule.departure_time.minute) < 0){
      hours = Math.floor(parseInt(schedule.departure_time.minute) / 60)
      minutes = (parseInt(schedule.departure_time.minute) % 60) + 60
      if(minutes == 60){
        minutes = 0
      }
      schedule.departure_time.minute = actions.simplePad(minutes, 'minute')
      schedule.departure_time.hour = parseInt(schedule.departure_time.hour) + hours
    }
    if (parseInt(schedule.arrival_time.minute) < 0){
      hours = Math.floor(parseInt(schedule.arrival_time.minute) / 60)
      minutes = (parseInt(schedule.arrival_time.minute) % 60) + 60
      if(minutes == 60){
        minutes = 0
      }
      schedule.arrival_time.minute = actions.simplePad(minutes, 'minute')
      schedule.arrival_time.hour = parseInt(schedule.arrival_time.hour) + hours
    }

    if(parseInt(schedule.departure_time.hour) > 23){
      schedule.departure_time.hour = '23'
      schedule.departure_time.minute = '59'
    }
    if(parseInt(schedule.arrival_time.hour) > 23){
      schedule.arrival_time.hour = '23'
      schedule.arrival_time.minute = '59'
    }

    if(parseInt(schedule.departure_time.hour) < 0){
      schedule.departure_time.hour = '00'
      schedule.departure_time.minute = '00'
    }
    if(parseInt(schedule.arrival_time.hour) < 0){
      schedule.arrival_time.hour = '00'
      schedule.arrival_time.minute = '00'
    }

    schedule.departure_time.hour = actions.simplePad(parseInt(schedule.departure_time.hour), 'hour')
    schedule.arrival_time.hour = actions.simplePad(parseInt(schedule.arrival_time.hour), 'hour')
    // if (parseInt(schedule.departure_time.hour) > 23){
    //   schedule.departure_time.hour = parseInt(schedule.departure_time.hour) - 24
    // }
    // if (parseInt(schedule.arrival_time.hour) > 23){
    //   schedule.arrival_time.hour = parseInt(schedule.arrival_time.hour) - 24
    // }
    // schedule.departure_time.hour = actions.pad(schedule.departure_time.hour, 'hour')
    // schedule.arrival_time.hour = actions.pad(schedule.arrival_time.hour, 'hour')
  }
}

module.exports = actions
