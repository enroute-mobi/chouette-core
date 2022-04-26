import _ from 'lodash'

let vehicleJourneysModal, newModalProps, vehicleJourney, alreadyPresent, notAlreadyPresent, newReferentialCodesArray, selectedConstraintZones

export default function modal(state = {}, action) {
  switch (action.type) {
    case 'OPEN_CONFIRM_MODAL':
      $('#ConfirmModal').modal('show')
      return _.assign({}, state, {
        type: 'confirm',
        confirmModal: {
          callback: action.callback,
        }
      })
    case 'EDIT_NOTES_VEHICLEJOURNEY_MODAL':
    // Prevent unwanted modification triggered by shallow copy
      let vehicleJourneyModal = _.cloneDeep(action.vehicleJourney)
      return {
        type: 'notes_edit',
        modalProps: {
          vehicleJourney: vehicleJourneyModal
        },
        confirmModal: {}
      }
    case 'TOGGLE_FOOTNOTE_MODAL':
      newModalProps = JSON.parse(JSON.stringify(state.modalProps))
      if(action.footnote.line_notice){
        if (action.isShown){
          newModalProps.vehicleJourney.line_notices.push(action.footnote)
        }else{
          newModalProps.vehicleJourney.line_notices = newModalProps.vehicleJourney.line_notices.filter((f) => {return f.id != action.footnote.id })
        }
      }
      else{
        if (action.isShown){
          newModalProps.vehicleJourney.footnotes.push(action.footnote)
        }else{
          newModalProps.vehicleJourney.footnotes = newModalProps.vehicleJourney.footnotes.filter((f) => {return f.id != action.footnote.id })
        }
      }
      return _.assign({}, state, {modalProps: newModalProps})
    case 'EDIT_VEHICLEJOURNEY_MODAL':
      return {
        type: 'edit',
        modalProps: {
          // Prevent unwanted modification triggered by shallow copy
          vehicleJourney: _.cloneDeep(action.vehicleJourney)
        },
        confirmModal: {}
      }
    case 'INFO_VEHICLEJOURNEY_MODAL':
      return {
        type: 'edit',
        modalProps: {
          vehicleJourney: action.vehicleJourney,
          info: true
        },
        confirmModal: {}
      }
    case 'EDIT_CALENDARS_VEHICLEJOURNEY_MODAL':
      vehicleJourneysModal = JSON.parse(JSON.stringify(action.vehicleJourneys))
      let uniqTimetables = []
      vehicleJourneysModal.map((vj, i) => {
        vj.time_tables.map((tt, j) =>{
          if(!(_.find(uniqTimetables, tt))){
            uniqTimetables.push(tt)
          }
        })
      })
      return {
        type: 'calendars_edit',
        modalProps: {
          vehicleJourneys: vehicleJourneysModal,
          timetables: uniqTimetables
        },
        confirmModal: {}
      }
    case 'EDIT_CONSTRAINT_EXCLUSIONS_VEHICLEJOURNEY_MODAL':
      var vehicleJourneys = JSON.parse(JSON.stringify(action.vehicleJourneys))
      let uniqExclusions = []
      let uniqStopAreasExclusions = []
      vehicleJourneys.map((vj, i) => {
        if(vj.ignored_routing_contraint_zone_ids){
          vj.ignored_routing_contraint_zone_ids.map((exclusion, j) =>{
            let found = false
            uniqExclusions.map((id, i)=>{
              if(id == parseInt(exclusion)){
                found = true
              }
            })
            if(!found){
              uniqExclusions.push(parseInt(exclusion))
            }
          })
        }
        if(vj.ignored_stop_area_routing_constraint_ids){
          vj.ignored_stop_area_routing_constraint_ids.map((exclusion, j) =>{
            let found = false
            uniqStopAreasExclusions.map((id, i)=>{
              if(id == parseInt(exclusion)){
                found = true
              }
            })
            if(!found){
              uniqStopAreasExclusions.push(parseInt(exclusion))
            }
          })
        }
      })
      return {
        type: 'constraint_exclusions_edit',
        modalProps: {
          vehicleJourneys: vehicleJourneys,
          selectedConstraintZones: uniqExclusions,
          selectedStopAreasConstraints: uniqStopAreasExclusions
        },
        confirmModal: {}
      }
    case 'SELECT_CP_EDIT_MODAL':
      vehicleJourney =  _.assign({}, state.modalProps.vehicleJourney, {company: action.selectedItem})
      newModalProps = _.assign({}, state.modalProps, {vehicleJourney})
      return _.assign({}, state, {modalProps: newModalProps})
    case 'UNSELECT_CP_EDIT_MODAL':
      vehicleJourney =  _.assign({}, state.modalProps.vehicleJourney, {company: undefined})
      newModalProps = _.assign({}, state.modalProps, {vehicleJourney})
      return _.assign({}, state, {modalProps: newModalProps})
    case 'ADD_REFERENTIAL_CODE_EDIT_MODAL':
      newReferentialCodesArray = state.modalProps.vehicleJourney.referential_codes
      newReferentialCodesArray.push(action.newCode)
      return {
        ...state,
        modalProps: {
          ...state.modalProps,
          vehicleJourney: {
            ...state.modalProps.vehicleJourney,
            referential_codes: newReferentialCodesArray
          }
        }
      }
    case 'DELETE_REFERENTIAL_CODE_EDIT_MODAL':
      newReferentialCodesArray = state.modalProps.vehicleJourney.referential_codes
      newReferentialCodesArray.splice(action.index, 1)
      return {
        ...state,
        modalProps: {
          ...state.modalProps,
          vehicleJourney: {
            ...state.modalProps.vehicleJourney,
            referential_codes: newReferentialCodesArray
          }
        }
      }
    case 'UPDATE_REFERENTIAL_CODE_EDIT_MODAL':
      return {
        ...state,
        modalProps: {
          ...state.modalProps,
          vehicleJourney: {
            ...state.modalProps.vehicleJourney,
            referential_codes: state.modalProps.vehicleJourney.referential_codes.map((code, index) =>
              index === action.index ? _.assign({}, code, action.attributes) : code
            )
          }
        }
      }
    case 'SELECT_TT_CALENDAR_MODAL':
      newModalProps = _.assign({}, state.modalProps, {selectedTimetable : action.selectedItem})
      return _.assign({}, state, {modalProps: newModalProps})
    case 'SELECT_CONSTRAINT_ZONE_MODAL':
      selectedConstraintZones = state.modalProps.selectedConstraintZones
      alreadyPresent = false
      selectedConstraintZones.map((zone_id, i)=>{
        if(zone_id == parseInt(action.selectedZone.id)){
          alreadyPresent = true
        }
      })
      if(alreadyPresent){ return state }
      selectedConstraintZones.push(parseInt(action.selectedZone.id))
      newModalProps = _.assign({}, state.modalProps, {selectedConstraintZones})
      return _.assign({}, state, {modalProps: newModalProps})
    case 'DELETE_CONSTRAINT_ZONE_MODAL':
        newModalProps = JSON.parse(JSON.stringify(state.modalProps))
        selectedConstraintZones = state.modalProps.selectedConstraintZones.slice(0)
        selectedConstraintZones.map((zone_id, i) =>{
          if(zone_id == parseInt(action.constraintZone.id)){
            selectedConstraintZones.splice(i, 1)
          }
        })
        newModalProps.selectedConstraintZones = selectedConstraintZones
        return _.assign({}, state, {modalProps: newModalProps})
    case 'SELECT_STOPAREAS_CONSTRAINT_MODAL':
      let selectedStopAreasConstraints = state.modalProps.selectedStopAreasConstraints
      alreadyPresent = false
      selectedStopAreasConstraints.map((zone_id, i)=>{
        if(zone_id == parseInt(action.selectedZone.id)){
          alreadyPresent = true
        }
      })
      if(alreadyPresent){ return state }
      selectedStopAreasConstraints.push(parseInt(action.selectedZone.id))
      newModalProps = _.assign({}, state.modalProps, {selectedStopAreasConstraints})
      return _.assign({}, state, {modalProps: newModalProps})
    case 'DELETE_STOPAREAS_CONSTRAINT_MODAL':
        newModalProps = JSON.parse(JSON.stringify(state.modalProps))
        selectedStopAreasConstraints = state.modalProps.selectedStopAreasConstraints.slice(0)
        selectedStopAreasConstraints.map((zone_id, i) =>{
          if(zone_id == parseInt(action.constraintZone.id)){
            selectedStopAreasConstraints.splice(i, 1)
          }
        })
        newModalProps.selectedStopAreasConstraints = selectedStopAreasConstraints
        return _.assign({}, state, {modalProps: newModalProps})
    case 'ADD_SELECTED_TIMETABLE':
      if(state.modalProps.selectedTimetable){
        newModalProps = JSON.parse(JSON.stringify(state.modalProps))
        if (!_.find(newModalProps.timetables, newModalProps.selectedTimetable)){
          newModalProps.timetables.push(newModalProps.selectedTimetable)
        }
        return _.assign({}, state, {modalProps: newModalProps})
      }
    case 'DELETE_CALENDAR_MODAL':
      newModalProps = JSON.parse(JSON.stringify(state.modalProps))
      let timetablesModal = state.modalProps.timetables.slice(0)
      timetablesModal.map((tt, i) =>{
        if(tt == action.timetable){
          timetablesModal.splice(i, 1)
        }
      })
      vehicleJourneysModal = state.modalProps.vehicleJourneys.slice(0)
      vehicleJourneysModal.map((vj) =>{
        vj.time_tables.map((tt, i) =>{
          if (_.isEqual(tt, action.timetable)){
            vj.time_tables.splice(i, 1)
          }
        })
      })
      newModalProps.vehicleJourneys = vehicleJourneysModal
      newModalProps.timetables = timetablesModal
      return _.assign({}, state, {modalProps: newModalProps})
    case 'CREATE_VEHICLEJOURNEY_MODAL':
      let selectedJP = {}
      if (window.jpOrigin){
        let stopAreas = _.map(window.jpOriginStopPoints, (sp, i) =>{
          return _.assign({}, { stop_area_short_description: { id: sp.stop_area_id, name: sp.name, position: sp.position, object_id: sp.area_object_id}})
        })
        selectedJP = _.assign({}, window.jpOrigin, {stop_areas: stopAreas})
      }
      return {
        type: 'create',
        modalProps: window.jpOrigin ? {selectedJPModal: selectedJP} : {},
        confirmModal: {}
      }
    case 'SELECT_JP_CREATE_MODAL':
      let selected = action.selectedItem
      delete selected["element"]
      newModalProps = _.assign({}, state.modalProps, {selectedJPModal : selected})
      return _.assign({}, state, {modalProps: newModalProps})
    case 'SHIFT_VEHICLEJOURNEY_MODAL':
      return {
        type: 'shift',
        modalProps: {},
        confirmModal: {}
      }
    case 'SELECT_SPECIFIC_STOP_MODAL':
    return {
      type: 'select_specific_stop',
      modalProps: {
        // Prevent unwanted modification triggered by shallow copy
        vehicleJourney: _.cloneDeep(action.vehicleJourney)
      },
      confirmModal: {}
    }
    case 'DUPLICATE_VEHICLEJOURNEY_MODAL':
      return {
        type: 'duplicate',
        modalProps: {},
        confirmModal: {}
      }
    case 'CLOSE_MODAL':
      return {
        type: '',
        modalProps: {},
        confirmModal: {}
      }
    default:
      return state
  }
}
