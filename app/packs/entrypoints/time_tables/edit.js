import React from 'react'
import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'
import applyMiddleware from '../../src/helpers/middlewares'
import timeTablesApp from '../../src/time_tables/reducers'
import App from '../../src/time_tables/containers/App'
import clone from '../../src/helpers/clone'

const actionType = clone(window, "actionType", true)

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

let store = createStore(
  timeTablesApp,
  initialState,
  applyMiddleware()
)

document.addEventListener("DOMContentLoaded", () => {
  if (document.getElementById("periods")) {
    render(
      <Provider store={store}>
        <App />
      </Provider>,
      document.getElementById('periods')
    )
  }
})