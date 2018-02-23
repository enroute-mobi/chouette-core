import Promise from 'promise-polyfill'

// To add to window
if (!window.Promise) {
  window.Promise = Promise;
}
import { batchActions } from '../batch'

const actions = {
  enterEditMode: () => ({
    type: "ENTER_EDIT_MODE"
  }),
  exitEditMode: () => ({
    type: "EXIT_EDIT_MODE"
  }),
  receiveVehicleJourneys : (json, returnJourneys) => ({
    type: (returnJourneys ? "RECEIVE_RETURN_VEHICLE_JOURNEYS" : "RECEIVE_VEHICLE_JOURNEYS"),
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
      short_id: selectedJP.short_id,
      name: selectedJP.name,
      published_name: selectedJP.published_name,
      stop_areas: selectedJP.stop_area_short_descriptions,
      costs: selectedJP.costs,
      full_schedule: selectedJP.full_schedule
    }
  }),
  openEditModal : (vehicleJourney) => ({
    type : 'EDIT_VEHICLEJOURNEY_MODAL',
    vehicleJourney
  }),
  openInfoModal : (vehicleJourney) => ({
    type : 'INFO_VEHICLEJOURNEY_MODAL',
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
      objectid: selectedTT.objectid,
      color: selectedTT.color,
      bounding_dates: selectedTT.time_table_bounding,
      days: selectedTT.day_types
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
  openPurchaseWindowsEditModal : (vehicleJourneys) => ({
    type : 'EDIT_PURCHASE_WINDOWS_VEHICLEJOURNEY_MODAL',
    vehicleJourneys
  }),
  selectPurchaseWindowsModal: (selectedWindow) =>({
    type: 'SELECT_PURCHASE_WINDOW_MODAL',
    selectedItem:{
      id: selectedWindow.id,
      name: selectedWindow.name,
      color: selectedWindow.color,
      objectid: selectedWindow.objectid
    }
  }),
  addSelectedPurchaseWindow: () => ({
    type: 'ADD_SELECTED_PURCHASE_WINDOW'
  }),
  deletePurchaseWindowsModal : (purchaseWindow) => ({
    type : 'DELETE_PURCHASE_WINDOW_MODAL',
    purchaseWindow
  }),
  editVehicleJourneyPurchaseWindows : (vehicleJourneys, purchase_windows) => ({
    type: 'EDIT_VEHICLEJOURNEYS_PURCHASE_WINDOWS',
    vehicleJourneys,
    purchase_windows
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
  unselect2Company: () => ({
    type: 'UNSELECT_CP_EDIT_MODAL',
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
  shiftVehicleJourney : (addtionalTime) => ({
    type: 'SHIFT_VEHICLEJOURNEY',
    addtionalTime
  }),
  duplicateVehicleJourney : (addtionalTime, duplicateNumber, departureDelta) => ({
    type: 'DUPLICATE_VEHICLEJOURNEY',
    addtionalTime,
    duplicateNumber,
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
    let valid = true
    Object.keys(fields).forEach((key) => {
      let field = fields[key]
      if(field.validity && !field.validity.valid){
        valid = false
        $(field).parent().parent().addClass('has-error').children('.help-block').remove()
        $(field).parent().append("<span class='small help-block'>" + field.validationMessage + "</span>")
      }
    })
    return valid
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
  fetchVehicleJourneys : (dispatch, currentPage, nextPage, queryString, url) => {
    let returnJourneys = false
    if(currentPage == undefined){
      currentPage = 1
    }
    if(url == undefined){
      url = window.location.pathname
    }
    else{
      returnJourneys = true
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
    let urlJSON = url + str
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
            var purchaseWindows = []
            let tt
            for (tt of val.time_tables){
              timeTables.push(tt)
            }
            if(val.purchase_windows){
              for (tt of val.purchase_windows){
                purchaseWindows.push(tt)
              }
            }
            let vjasWithDelta = val.vehicle_journey_at_stops.map((vjas, i) => {
              actions.fillEmptyFields(vjas)
              return actions.getDelta(vjas)
            })

            vehicleJourneys.push(
              _.assign({}, val, {
                time_tables: timeTables,
                purchase_windows: purchaseWindows,
                vehicle_journey_at_stops: vjasWithDelta,
                deletable: false,
                selected: false,
                published_journey_name: val.published_journey_name || 'non renseigné',
                published_journey_identifier: val.published_journey_identifier || 'non renseigné',
                company: val.company || {name: 'non renseigné'},
                transport_mode: val.route.line.transport_mode || 'undefined',
                transport_submode: val.route.line.transport_submode || 'undefined'
              })
            )
          }
          window.currentItemsLength = vehicleJourneys.length
          dispatch(actions.receiveVehicleJourneys(vehicleJourneys, returnJourneys))
          if(!returnJourneys){
            dispatch(actions.receiveTotalCount(json.total))
          }
        }
      })
  },

  validate : (dispatch, vehicleJourneys, next) => {
    dispatch(actions.didValidateVehicleJourneys(vehicleJourneys))
    actions.submitVehicleJourneys(dispatch, vehicleJourneys, next)
    return true
  },

  didValidateVehicleJourneys : (vehicleJourneys) => ({
    type: 'DID_VALIDATE_VEHICLE_JOURNEYS',
    vehicleJourneys
  }),

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
            dispatch(actions.exitEditMode())
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
      return '0' + d.toString()
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
    if (original.departure_time.hour != '' && original.departure_time.minute != '' && newDeparture.departure_time.hour != undefined && newDeparture.departure_time.minute != undefined){
      return  (newDeparture.departure_time.hour - parseInt(original.departure_time.hour)) * 60 + (newDeparture.departure_time.minute - parseInt(original.departure_time.minute))
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
  adjustSchedule: (action, schedule) => {
    // we enforce that the departure time remains after the arrival time
    actions.getDelta(schedule)
    if(schedule.delta < 0){
      if(action.isDeparture){
        schedule.arrival_time = schedule.departure_time
      }
      else{
        schedule.departure_time = schedule.arrival_time
      }
      actions.getDelta(schedule)
    }
    return schedule
  },
  getShiftedSchedule: ({departure_time, arrival_time}, additional_time) => {
    // We create dummy dates objects to manipulate time more easily
    let departureDT = new Date (Date.UTC(2017, 2, 1, parseInt(departure_time.hour), parseInt(departure_time.minute)))
    let arrivalDT = new Date (Date.UTC(2017, 2, 1, parseInt(arrival_time.hour), parseInt(arrival_time.minute)))

    let newDepartureDT = new Date (departureDT.getTime() + additional_time * 60000)
    let newArrivalDT = new Date (arrivalDT.getTime() + additional_time * 60000)

    return {
      departure_time: {
        hour: actions.simplePad(newDepartureDT.getUTCHours()),
        minute: actions.simplePad(newDepartureDT.getUTCMinutes())
      },
      arrival_time: {
        hour: actions.simplePad(newArrivalDT.getUTCHours()),
        minute: actions.simplePad(newArrivalDT.getUTCMinutes())
      }
    }
  },
  addMinutesToTime: (time, minutes) => {
    let res = {
      hour: time.hour,
      minute: time.minute
    }
    let delta_hour = parseInt(minutes/60)
    let delta_minute = minutes - 60*delta_hour
    res.hour += delta_hour
    res.minute += delta_minute
    let extra_hours = parseInt(res.minute/60)
    res.hour += extra_hours
    res.minute -= extra_hours*60
    res.hour = res.hour % 24

    return res
  }
}

export default actions
