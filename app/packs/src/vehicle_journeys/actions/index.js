import { batchActions } from '../batch'

const actions = {
  enterEditMode: () => ({
    type: "ENTER_EDIT_MODE"
  }),
  exitEditMode: () => ({
    type: "EXIT_EDIT_MODE"
  }),
  onVisibilityChange: (event) => ({
    type: "VISIBILITY_CHANGE", event
  }),
  toggleTimesSelection: () => ({
    type: "TOGGLE_SELECTION_MODE"
  }),
  updateSelectedItems: items => ({
    type: 'UPDATE_SELECTED_ITEMS', items
  }),
  clearSelectedItems: () => ({
    type: 'CLEAR_SELECTED_ITEMS'
  }),
  updateSelectionDimensions: (width, height) => ({
    type: 'UPDATE_SELECTION_DIMENSIONS', width, height
  }),
  updateSelectionLocked: locked => ({
    type: 'UPDATE_SELECTION_LOCKED', locked
  }),
  copyClipboard: () => ({
    type: 'COPY_CLIPBOARD'
  }),
  pasteFromClipboard: ()=>({
    type: "PASTE_CLIPBOARD"
  }),
  closeCopyModal: ()=>({
    type: "CLOSE_COPY_MODAL"
  }),
  copyModalToPasteMode: ()=>({
    type: "COPY_MODAL_TO_PASTE_MODE"
  }),
  copyModalToCopyMode: () => ({
    type: "COPY_MODAL_TO_COPY_MODE"
  }),
  updateContentToPaste:  content =>({
    type: "UPDATE_CONTENT_TO_PASTE", content
  }),
  pasteContent: ()=>({
    type: "PASTE_CONTENT"
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
    selectedItem: _.assign({}, selectedJP, {
      objectid: selectedJP.object_id,
      stop_areas: selectedJP.stop_area_short_descriptions
    })
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
  editVehicleJourneyConstraintZones : (vehicleJourneys, zones, stop_area_constraints) => ({
    type: 'EDIT_VEHICLEJOURNEYS_CONSTRAINT_ZONES',
    vehicleJourneys,
    zones,
    stop_area_constraints
  }),
  openConstraintExclusionEditModal : (vehicleJourneys) => ({
    type : 'EDIT_CONSTRAINT_EXCLUSIONS_VEHICLEJOURNEY_MODAL',
    vehicleJourneys
  }),
  selectConstraintZone: (selectedZone) =>({
    type: 'SELECT_CONSTRAINT_ZONE_MODAL',
    selectedZone: {
      id: selectedZone.id,
      name: selectedZone.text
    }
  }),
  selectStopAreasConstraint: (selectedZone) =>({
    type: 'SELECT_STOPAREAS_CONSTRAINT_MODAL',
    selectedZone: {
      id: selectedZone.id,
      name: selectedZone.text
    }
  }),
  deleteConstraintZone : (constraintZone) => ({
    type : 'DELETE_CONSTRAINT_ZONE_MODAL',
    constraintZone
  }),
  deleteStopAreasConstraint : (constraintZone) => ({
    type : 'DELETE_STOPAREAS_CONSTRAINT_MODAL',
    constraintZone
  }),
  openShiftModal : () => ({
    type : 'SHIFT_VEHICLEJOURNEY_MODAL'
  }),
  openSelectSpecificStopModal : (vehicleJourney) => ({
    type : 'SELECT_SPECIFIC_STOP_MODAL',
    vehicleJourney
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
  select2Company: selectedItem => ({
    type: 'SELECT_CP_EDIT_MODAL',
    selectedItem
  }),
  unselect2Company: () => ({
    type: 'UNSELECT_CP_EDIT_MODAL',
  }),
  addReferentialCode: (newCode) => ({
    type: 'ADD_REFERENTIAL_CODE_EDIT_MODAL',
    newCode
  }),
  deleteReferentialCode: (index) => ({
    type: 'DELETE_REFERENTIAL_CODE_EDIT_MODAL',
    index
  }),
  updateReferentialCode: (index, attributes) => ({
    type: 'UPDATE_REFERENTIAL_CODE_EDIT_MODAL',
    index,
    attributes
  }),
  editVehicleJourney : (data, selectedCompany) => ({
    type: 'EDIT_VEHICLEJOURNEY',
    data,
    selectedCompany
  }),
  editVehicleJourneyNotes : (footnotes, line_notices) => ({
    type: 'EDIT_VEHICLEJOURNEY_NOTES',
    footnotes,
    line_notices
  }),
  shiftVehicleJourney : (addtionalTime) => ({
    type: 'SHIFT_VEHICLEJOURNEY',
    addtionalTime
  }),
  selectSpecificStop : (specific_stop_area_map) => ({
    type: 'SELECT_SPECIFIC_STOP',
    specific_stop_area_map
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
  cancelDeletion : () => ({
    type: 'CANCEL_DELETION'
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
  updateTime : (val, subIndex, index, timeUnit, isDeparture, isArrivalsToggled, enforceConsistency=false) => ({
    type: 'UPDATE_TIME',
    val,
    subIndex,
    index,
    timeUnit,
    isDeparture,
    isArrivalsToggled,
    enforceConsistency
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
    if (!returnJourneys && queryString){
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
          let i = 0
          while(i < json.vehicle_journeys.length){
            let val = json.vehicle_journeys[i]
            i++
            var timeTables = []
            let k = 0
            while(k < val.time_tables.length){
              let tt = val.time_tables[k]
              k++
              timeTables.push(tt)
            }
            let vjasWithDelta = val.vehicle_journey_at_stops.map((vjas, i) => {
              actions.fillEmptyFields(vjas)
              return actions.getDelta(vjas)
            })

            var line_notices = val['public.line_notices']
            if(! line_notices.map){
              line_notices = []
            }
            vehicleJourneys.push(
              _.assign({}, val, {
                time_tables: timeTables,
                vehicle_journey_at_stops: vjasWithDelta,
                deletable: false,
                selected: false,
                published_journey_name: val.published_journey_name || '',
                published_journey_identifier: val.published_journey_identifier || '',
                company: val.company || {name: ''},
                transport_mode: val.route.line.transport_mode || 'undefined',
                transport_submode: val.route.line.transport_submode || 'undefined',
                line_notices: line_notices
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
    let urlJSON = window.location.pathname + ".json"
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
  getSelectedDeletables: (vj) => {
    return actions.getSelected(vj).filter(obj => obj.deletable)
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
  getDelta: (vjas, allowNegative=false) => {
    let { hasAllAttributes, departure_time, arrival_time} = actions.scheduleToDates(vjas)
    let delta = 0

    if (hasAllAttributes) {
      if (arrival_time.getHours() == 23 && (departure_time.getHours() == 0 || (departure_time.getHours() == 1 && departure_time.getMinutes() == 0)))  {
        departure_time.setDate(arrival_time.getDate() + 1)
      }

      // We want the delta in minutes
      delta = (departure_time.getTime() - arrival_time.getTime()) / 60000
    }

    if (!allowNegative && delta < 0) {
      delta = 0
    }
    vjas.delta = delta
    return vjas
  },
  adjustSchedule: (action, schedule, isFirstOrLastStop, enforceConsistency=false) => {
    // we enforce that the departure time remains after the arrival time
    if (!enforceConsistency) return actions.getDelta(schedule, false)

    let newSchedule = actions.getDelta(schedule, true)

    if (newSchedule.delta < 0 || isFirstOrLastStop) {
      if (action.isDeparture) {
        newSchedule.arrival_time = newSchedule.departure_time
      }
      else {
        newSchedule.departure_time = newSchedule.arrival_time
      }
    }
    return actions.getDelta(newSchedule)
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
  scheduleToDates: (vjas) =>{
    let { departure_time: { hour: depHour, minute: depMinute } } = vjas
    let { arrival_time: { hour: arrHour, minute: arrMinute } } = vjas

    let hasAllAttributes = depHour != '' && depMinute != '' && arrHour != '' && arrMinute != ''
    return {
      hasAllAttributes,
      departure_time: hasAllAttributes && new Date(2017, 2, 1, parseInt(depHour), parseInt(depMinute)),
      arrival_time: hasAllAttributes && new Date(2017, 2, 1, parseInt(arrHour), parseInt(arrMinute))
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
