import React from 'react'
import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'
import vehicleJourneysApp from '../../vehicle_journeys/reducers'
import App from '../../vehicle_journeys/components/App'
import actions from "../../vehicle_journeys/actions"
import { enableBatching } from '../../vehicle_journeys/batch'

// logger, DO NOT REMOVE
// var applyMiddleware = require('redux').applyMiddleware
// import { createLogger } from 'redux-logger';
// var thunkMiddleware = require('redux-thunk').default
// var promise = require('redux-promise')

var selectedJP = []

if (window.journeyPatternId)
  selectedJP.push(window.journeyPatternId)

var initialState = {
  editMode: false,
  filters: {
    selectedJourneyPatterns : selectedJP,
    policy: window.perms,
    features: window.features,
    toggleArrivals: false,
    queryString: '',
    query: {
      interval: {
        start:{
          hour: '00',
          minute: '00'
        },
        end:{
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
    page : 1,
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
  custom_fields: window.custom_fields
}

if (window.jpOrigin){
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

// const loggerMiddleware = createLogger()

let store = createStore(
  enableBatching(vehicleJourneysApp),
  initialState,
  // applyMiddleware(thunkMiddleware, promise, loggerMiddleware)
)

render(
  <Provider store={store}>
    <App returnRouteUrl={window.returnRouteUrl} />
  </Provider>,
  document.getElementById('vehicle_journeys_wip')
)
