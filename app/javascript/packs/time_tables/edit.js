import '../../helpers/polyfills'

import React from 'react'
import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'
import timeTablesApp from '../../time_tables/reducers'
import App from '../../time_tables/containers/App'
import clone from '../../helpers/clone'

const actionType = clone(window, "actionType", true)

// logger, DO NOT REMOVE
// var applyMiddleware = require('redux').applyMiddleware
// import { createLogger } from 'redux-logger';
// var thunkMiddleware = require('redux-thunk').default
// var promise = require('redux-promise')

let initialState = {
  status: {
    actionType: actionType,
    policy: window.perms,
    fetchSuccess: true,
    isFetching: false
  },
  timetable: {
    current_month: [],
    current_periode_range: '',
    periode_range: [],
    time_table_periods: [],
    time_table_dates: []
  },
  metas: {
    comment: '',
    day_types: [],
    tags: [],
    color: '',
    calendar: null
  },
  pagination: {
    stateChanged: false,
    currentPage: '',
    periode_range: []
  },
  modal: {
    type: '',
    modalProps: {
      active: false,
      begin: {
        day: '01',
        month: '01',
        year: String(new Date().getFullYear())
      },
      end: {
        day: '01',
        month: '01',
        year: String(new Date().getFullYear())
      },
      index: false,
      error: ''
    },
    confirmModal: {}
  }
}
// const loggerMiddleware = createLogger()

let store = createStore(
  timeTablesApp,
  initialState,
  // applyMiddleware(thunkMiddleware, promise, loggerMiddleware)
)

render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById('periods')
)
