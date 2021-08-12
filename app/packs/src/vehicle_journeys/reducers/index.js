import { combineReducers } from 'redux'
import actions from '../actions'
import vehicleJourneys from './vehicleJourneys'
import returnVehicleJourneys from './returnVehicleJourneys'
import pagination from './pagination'
import modal from './modal'
import status from './status'
import filters from './filters'
import editMode from './editMode'
import selection from './selection'
import stopPointsList from './stopPointsList'
import missions from './missions'
import custom_fields from './custom_fields'

var selectedJP = []

if (window.journeyPatternId)
  selectedJP.push(window.journeyPatternId)

const initialState = {
  editMode: false,
  filters: {
    selectedJourneyPatterns: selectedJP,
    policy: window.perms,
    features: window.features,
    toggleArrivals: false,
    queryString: '',
    query: {
      interval: {
        start: {
          hour: '00',
          minute: '00'
        },
        end: {
          hour: '23',
          minute: '59'
        }
      },
      journeyPattern: {
        published_name: ''
      },
      vehicleJourney: {
        objectid: ''
      },
      company: {
        name: ''
      },
      timetable: {
        comment: ''
      },
      withoutSchedule: true,
      withoutTimeTable: true
    }

  },
  status: {
    fetchSuccess: false,
    isFetching: false
  },
  vehicleJourneys: [],
  stopPointsList: window.stopPoints,
  returnStopPointsList: window.returnStopPoints,
  pagination: {
    page: 1,
    totalCount: 0,
    perPage: window.vehicleJourneysPerPage,
    stateChanged: false
  },
  modal: {
    type: '',
    modalProps: {},
    confirmModal: {}
  },
  missions: window.all_missions,
  custom_fields: window.custom_fields,
  selection: {
    active: false,
    width: 0,
    height: 0,
    copyModal: {
      visible: false,
      mode: 'copy',
      content: {
        copy: '',
        paste: ''
      }
    },
    items: []
  }
}

if (window.jpOrigin) {
  initialState.filters.query.journeyPattern = {
    id: window.jpOrigin.id,
    name: window.jpOrigin.name,
    published_name: window.jpOrigin.published_name,
    objectid: window.jpOrigin.objectid
  }
  let params = {
    'q[journey_pattern_id_eq]': initialState.filters.query.journeyPattern.id,
    'q[objectid_cont]': initialState.filters.query.vehicleJourney.objectid
  }
  initialState.filters.queryString = actions.encodeParams(params)
}

export { initialState }

const combinedReducers = combineReducers({
  vehicleJourneys,
  returnVehicleJourneys,
  pagination,
  modal,
  status,
  filters,
  editMode,
  stopPointsList,
  returnStopPointsList: stopPointsList,
  missions,
  custom_fields,
  selection: (state = {}, action) => state
})

export default function(state = {}, action) {
  const newState = combinedReducers(state, action)

  return selection(newState, action)
}
