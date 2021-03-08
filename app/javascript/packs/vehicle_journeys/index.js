import '../../helpers/polyfills'

import React from 'react'
import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'
import vehicleJourneysApp from '../../vehicle_journeys/reducers'
import App from '../../vehicle_journeys/components/App'
import { enableBatching } from '../../vehicle_journeys/batch'

import { initialState } from '../../vehicle_journeys/reducers'

// logger, DO NOT REMOVE
var applyMiddleware = require('redux').applyMiddleware
import { createLogger } from 'redux-logger';
var thunkMiddleware = require('redux-thunk').default
var promise = require('redux-promise')

const loggerMiddleware = createLogger()

let store = createStore(
  enableBatching(vehicleJourneysApp),
  initialState,
  applyMiddleware(thunkMiddleware, promise, loggerMiddleware)
)

render(
  <Provider store={store}>
    <App returnRouteUrl={window.returnRouteUrl} />
  </Provider>,
  document.getElementById('vehicle_journeys_wip')
)
