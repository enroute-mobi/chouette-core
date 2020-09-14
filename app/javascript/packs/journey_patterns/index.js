import '../../helpers/polyfills'

import React from 'react'
import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'
import journeyPatternsApp from '../../journey_patterns/reducers'
import App from '../../journey_patterns/components/App'
import clone from '../../helpers/clone'

import RoutesMap from '../../helpers/routes_map'


let route = clone(window, "route", true)
route = JSON.parse(decodeURIComponent(route))

new RoutesMap('route_map').prepare().then(function(map){
  map.addRoute(route)
  map.fitZoom()
})

// logger, DO NOT REMOVE
var applyMiddleware = require('redux').applyMiddleware
import { createLogger } from 'redux-logger';
var thunkMiddleware = require('redux-thunk').default
var promise = require('redux-promise')

var initialState = {
  editMode: false,
  status: {
    policy: window.perms,
    features: window.features,
    fetchSuccess: true,
    isFetching: false
  },
  journeyPatterns: [],
  stopPointsList: window.stopPoints,
  pagination: {
    page : 1,
    totalCount: window.journeyPatternLength,
    perPage: window.journeyPatternsPerPage,
    stateChanged: false
  },
  modal: {
    type: '',
    modalProps: {},
    confirmModal: {}
  },
  custom_fields: window.custom_fields
}
const loggerMiddleware = createLogger()

let store = createStore(
  journeyPatternsApp,
  initialState,
  applyMiddleware(thunkMiddleware, promise, loggerMiddleware)
)

render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById('journey_patterns')
)
