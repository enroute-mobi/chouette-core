import _ from 'lodash'
import actions from '../actions'

const vehicleJourney= (state = {}, action, keep) => {
  switch (action.type) {
    case 'SELECT_VEHICLEJOURNEY':
      return _.assign({}, state, {selected: !state.selected})
    case 'CANCEL_SELECTION':
      return _.assign({}, state, {selected: false})
    case 'CANCEL_DELETION':
      return _.assign({}, state, {deletable: false})
    case 'ADD_VEHICLEJOURNEY':
      let pristineVjasList = []
      let prevSp
      let current_time = {
        hour: 0,
        minute: 0
      }
      let computeSchedule = false
      let initTZOffet = 0
      if(action.data["start_time.hour"] && action.data["start_time.hour"].value && action.data["start_time.hour"].value.length > 0 && action.data["start_time.minute"] && action.selectedJourneyPattern.full_schedule && action.selectedJourneyPattern.costs){
        computeSchedule = true
        initTZOffet = - action.stopPointsList[0].time_zone_offset / 60 || 0
        current_time.hour = parseInt(action.data["start_time.hour"].value) + parseInt(initTZOffet / 60)
        current_time.minute = 0
        if(action.data["start_time.minute"].value){
          current_time.minute = parseInt(action.data["start_time.minute"].value) + (initTZOffet - 60 * parseInt(initTZOffet / 60))
        }
      }

      _.each(action.stopPointsList, (sp) => {
        let inJourney = false
        let newVjas

        if(computeSchedule){
          if(prevSp && action.selectedJourneyPattern.costs[prevSp.stop_area_id + "-" + sp.stop_area_id]){
            let delta = parseInt(action.selectedJourneyPattern.costs[prevSp.stop_area_id + "-" + sp.stop_area_id].time)
            current_time = actions.addMinutesToTime(current_time, delta)
            prevSp = sp
            inJourney = true
          }
          if(!prevSp){
            _.each(action.selectedJourneyPattern.stop_areas, (jp) => {
              if (jp.stop_area_short_description.id == sp.id){
                prevSp = sp
                return
              }
            })
          }

          let offsetHours = sp.time_zone_offset / 3600
          let offsetminutes = sp.time_zone_offset/60 - 60*offsetHours

          newVjas = {
            delta: 0,
            arrival_time:{
              hour: (24 + current_time.hour + offsetHours) % 24,
              minute: current_time.minute + offsetminutes
            },
            stop_point_objectid: sp.object_id,
            stop_area_cityname: sp.city_name,
            dummy: true,
            stop_point_id: sp.id,
            stop_area_id: sp.stop_area_id
          }

          if(sp.waiting_time && inJourney){
            current_time = actions.addMinutesToTime(current_time, parseInt(sp.waiting_time))
            newVjas.delta = parseInt(sp.waiting_time)
          }

          newVjas.departure_time = {
            hour: (24 + current_time.hour + offsetHours) % 24,
            minute: current_time.minute + offsetminutes
          }

          if(current_time.hour + offsetHours > 24){
            newVjas.departure_day_offset = 1
            newVjas.arrival_day_offset = 1
          }
        }
        else{
          newVjas = {
            delta: 0,
            arrival_time: {
              hour: 0,
              minute: 0
            },
            departure_time: {
              hour: 0,
              minute: 0
            },
            stop_point_objectid: sp.object_id,
            stop_area_cityname: sp.city_name,
            dummy: true,
            stop_point_id: sp.id,
            stop_area_id: sp.stop_area_id
          }
        }

        let belongToJP = !!action.selectedJourneyPattern.stop_areas.find(({ stop_area_short_description: stopArea }) => stopArea.object_id == sp.area_object_id && stopArea.position == sp.position)

        if (belongToJP) newVjas.dummy = false

        let lastStop = action.selectedJourneyPattern.stop_areas && action.selectedJourneyPattern.stop_areas[action.selectedJourneyPattern.stop_areas.length - 1]
        if(lastStop && lastStop.stop_area_short_description.id == sp.id){
          newVjas.departure_time = newVjas.arrival_time
          newVjas.delta = 0
        }

        if(newVjas.dummy){
          newVjas.departure_time = {hour: "00", minute: "00"}
          newVjas.arrival_time = {hour: "00", minute: "00"}
        }
        pristineVjasList.push(newVjas)

      })

      return {
        company: action.selectedCompany,
        journey_pattern: action.selectedJourneyPattern,
        published_journey_name: action.data.published_journey_name.value,
        published_journey_identifier: action.data.published_journey_identifier.value,
        objectid: '',
        short_id: '',
        footnotes: [],
        time_tables: [],
        line_notices: [],
        ignored_routing_contraint_zone_ids: [],
        vehicle_journey_at_stops: pristineVjasList,
        selected: false,
        deletable: false,
        transport_mode: window.transportMode ? window.transportMode : 'undefined',
        transport_submode: window.transportSubmode ? window.transportSubmode : 'undefined',
        custom_fields: action.data.custom_fields,
        referential_codes: []
      }
    case 'DUPLICATE_VEHICLEJOURNEY':
    case 'SHIFT_VEHICLEJOURNEY':
      let shiftedArray, shiftedSchedule, shiftedVjas
      shiftedArray = state.vehicle_journey_at_stops.map((vjas, i) => {
        if (!vjas.dummy){
          shiftedSchedule = actions.getShiftedSchedule(vjas, action.addtionalTime)

          shiftedVjas =  _.assign({}, state.vehicle_journey_at_stops[i], shiftedSchedule)
          vjas = _.assign({}, state.vehicle_journey_at_stops[i], shiftedVjas)
          if(!keep){
            delete vjas['id']
          }
          return vjas
        }else {
          if(!keep){
            delete vjas['id']
          }
          return vjas
        }
      })

      let custom_fields = JSON.parse(JSON.stringify(state.custom_fields))
      return _.assign({}, state, {vehicle_journey_at_stops: shiftedArray, custom_fields: custom_fields})
    case 'SELECT_SPECIFIC_STOP':
      let specific_stop_area_map = action.specific_stop_area_map
      let vjasList = state.vehicle_journey_at_stops.map((vjas, i) => {
        if (Object.keys(specific_stop_area_map).includes(vjas.stop_point_id.toString())) {
          vjas.specific_stop_area_id = specific_stop_area_map[vjas.stop_point_id]
        }
        return vjas
      })
      return _.assign({}, state, {vehicle_journey_at_stops: vjasList})
    case 'UPDATE_TIME':
      let vj, vjas, vjasArray, newSchedule
      let val = action.val
      let isFirstOrLastStop = action.subIndex == 0 || action.subIndex == (state.vehicle_journey_at_stops.length - 1)
      if(val != ''){
        val = parseInt(val)
        if(action.timeUnit == "minute"){
          val = (val + 60) % 60
        }
        else{
          val = (val + 24) % 24
        }
      }
      vjasArray = state.vehicle_journey_at_stops.map((vjas, i) => {
        if(i == action.subIndex){
          let schedule = {
            departure_time: _.assign({}, vjas.departure_time),
            arrival_time: _.assign({}, vjas.arrival_time)
          }
          newSchedule = _.assign({}, schedule)
          if (action.isDeparture){
            actions.getDelta(schedule, false)
            newSchedule.departure_time[action.timeUnit] = actions.pad(val, action.timeUnit)
            if(!action.isArrivalsToggled){
              schedule = actions.getShiftedSchedule({arrival_time: newSchedule.departure_time, departure_time: newSchedule.departure_time}, - schedule.delta)
              newSchedule.arrival_time = schedule.arrival_time
            }

            newSchedule = actions.adjustSchedule(action, newSchedule, isFirstOrLastStop, action.enforceConsistency)
            return _.assign({}, state.vehicle_journey_at_stops[action.subIndex], {arrival_time: newSchedule.arrival_time, departure_time: newSchedule.departure_time, delta: newSchedule.delta})
          }else{
            newSchedule.arrival_time[action.timeUnit] = actions.pad(val, action.timeUnit)
            newSchedule = actions.adjustSchedule(action, newSchedule, isFirstOrLastStop, action.enforceConsistency)
            return _.assign({}, state.vehicle_journey_at_stops[action.subIndex],  {arrival_time: newSchedule.arrival_time, departure_time: newSchedule.departure_time, delta: newSchedule.delta})
          }
        }else{
          return vjas
        }
      })
      return _.assign({}, state, {vehicle_journey_at_stops: vjasArray})
    default:
      return state
  }
}

export default function vehicleJourneys(state = [], action) {
  switch (action.type) {
    case 'RECEIVE_VEHICLE_JOURNEYS':
      return [...action.json]
    case 'RECEIVE_ERRORS':
      return [...action.json]
    case 'GO_TO_PREVIOUS_PAGE':
      if(action.pagination.page > 1){
        actions.fetchVehicleJourneys(action.dispatch, action.pagination.page, action.nextPage, action.queryString)
      }
      return state
    case 'GO_TO_NEXT_PAGE':
      if (action.pagination.totalCount - (action.pagination.page * action.pagination.perPage) > 0){
        actions.fetchVehicleJourneys(action.dispatch, action.pagination.page, action.nextPage, action.queryString)
      }
      return state
    case 'ADD_VEHICLEJOURNEY':
      return [
        vehicleJourney(state, action),
        ...state
      ]
    case 'EDIT_VEHICLEJOURNEY':
      return state.map((vj, i) => {
        if (vj.selected){
          return _.assign({}, vj, {
            company: action.selectedCompany,
            published_journey_name: action.data.published_journey_name.value,
            published_journey_identifier: action.data.published_journey_identifier.value,
            custom_fields: action.data.custom_fields,
            referential_codes: action.data.referential_codes
          })
        }else{
          return vj
        }
      })
    case 'EDIT_VEHICLEJOURNEY_NOTES':
      return state.map((vj, i) => {
        if (vj.selected){
          return _.assign({}, vj, {
            footnotes: action.footnotes,
            line_notices: action.line_notices
          })
        }else{
          return vj
        }
      })
    case 'EDIT_VEHICLEJOURNEYS_TIMETABLES':
      let newTimetables = JSON.parse(JSON.stringify(action.timetables))
      return state.map((vj,i) => {
        if(vj.selected){
          let updatedVJ = _.assign({}, vj)
          action.vehicleJourneys.map((vjm, j) => {
            if(vj.objectid == vjm.objectid){
              updatedVJ.time_tables =  newTimetables
            }
          })
          return updatedVJ
        }else{
          return vj
        }
      })
    case 'EDIT_VEHICLEJOURNEYS_CONSTRAINT_ZONES':
      let newExclusions = JSON.parse(JSON.stringify(action.zones))
      let newStopAreasExclusions = JSON.parse(JSON.stringify(action.stop_area_constraints))
      return state.map((vj,i) => {
        if(vj.selected){
          let updatedVJ = _.assign({}, vj)
          action.vehicleJourneys.map((vjm, j) => {
            if(vj.objectid == vjm.objectid){
              updatedVJ.ignored_routing_contraint_zone_ids =  newExclusions
              updatedVJ.ignored_stop_area_routing_constraint_ids =  newStopAreasExclusions
            }
          })
          return updatedVJ
        }else{
          return vj
        }
      })
    case 'SHIFT_VEHICLEJOURNEY':
      return state.map((vj, i) => {
        if (vj.selected){
          return vehicleJourney(vj, action, true)
        }else{
          return vj
        }
      })
    case 'SELECT_SPECIFIC_STOP':
      return state.map((vj, i) => {
        if (vj.selected){
          return vehicleJourney(vj, action, true)
        }else{
          return vj
        }
      })
    case 'DUPLICATE_VEHICLEJOURNEY':
      let dupeVj
      let dupes = []
      let selectedIndex
      let val = action.addtionalTime
      let departureDelta = action.departureDelta
      state.map((vj, i) => {
        if(vj.selected){
          selectedIndex = i
          for (i = 0; i< action.duplicateNumber; i++){
            // We check if the departureDelta is != 0 to create the first VJ on the updated deparure time if it is the case
            // let delta = departureDelta == 0 ? 1 : 0
            // action.addtionalTime = (val * (i + delta)) + departureDelta
            action.addtionalTime = (val * (i + 1)) + departureDelta
            dupeVj = vehicleJourney(vj, action, false)
            dupeVj.published_journey_name = dupeVj.published_journey_name + '-' + i
            dupeVj.selected = false
            dupeVj.referential_codes = []
            delete dupeVj['objectid']
            delete dupeVj['short_id']
            dupes.push(dupeVj)
          }
        }
      })
      let concatArray = state.slice(0, selectedIndex + 1).concat(dupes)
      concatArray = concatArray.concat(state.slice(selectedIndex + 1))
      return concatArray.map((vj, i) => {
        vj.index = i
        return vj
      })
    case 'DELETE_VEHICLEJOURNEYS':
      return state.map((vj, i) => {
        if (vj.selected){
          return _.assign({}, vj, {deletable: true, selected: false})
        } else {
          return vj
        }
      })
    case 'SELECT_VEHICLEJOURNEY':
      return state.map((vj, i) => {
        if (i == action.index){
          return vehicleJourney(vj, action)
        } else {
          return vj
        }
      })
    case 'CANCEL_SELECTION':
      return state.map((vj) => {
        return vehicleJourney(vj, action)
      })
    case 'CANCEL_DELETION':
      return state.map((vj) => {
        if (vj.selected && vj.deletable) {
          return vehicleJourney(vj, action)
        } else {
          return vj
        }
      })
    case 'UPDATE_TIME':
      return state.map((vj, i) => {
        if (i == action.index){
          return vehicleJourney(vj, action)
        } else {
          return vj
        }
      })
    case 'DID_VALIDATE_VEHICLE_JOURNEYS':
      return [...action.vehicleJourneys]

    default:
      return state
  }
}
