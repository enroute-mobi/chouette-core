var React = require('react')
var render = require('react-dom').render
var Provider = require('react-redux').Provider
var createStore = require('redux').createStore
var timeTablesApp = require('./reducers')
var App = require('./containers/App')

// logger, DO NOT REMOVE
// var applyMiddleware = require('redux').applyMiddleware
// var createLogger = require('redux-logger')
// var thunkMiddleware = require('redux-thunk').default
// var promise = require('redux-promise')

var initialState = {
  status: {
    actionType: window.actionType,
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
    initial_tags: [],
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
