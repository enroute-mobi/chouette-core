import React from 'react'
import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'
import applyMiddleware from '../../src/helpers/middlewares'
import journeyPatternsApp from '../../src/journey_patterns/reducers'
import App from '../../src/journey_patterns/components/App'

const initialState = {
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

const store = createStore(
  journeyPatternsApp,
  initialState,
  applyMiddleware()
)

render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById('journey_patterns')
)
