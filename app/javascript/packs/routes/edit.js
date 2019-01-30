import '../../helpers/polyfills'

import React from 'react'
import PropTypes from 'prop-types'

import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'

import reducers from '../../routes/reducers'
import App from '../../routes/components/App'
import RouteFormHelper from '../../routes/form_helper'
import clone from '../../helpers/clone'
let datas = clone(window, "itinerary_stop", true)
datas = JSON.parse(decodeURIComponent(datas))

// logger, DO NOT REMOVE
var applyMiddleware = require('redux').applyMiddleware
import {createLogger} from 'redux-logger';
var thunkMiddleware = require('redux-thunk').default
var promise = require('redux-promise')

const getInitialState = () => {
  let state = []

  datas.map(function (v, i) {
    let fancyText = v.name.replace("&#39;", "\'")
    if (v.zip_code && v.city_name)
      fancyText += ", " + v.zip_code + " " + v.city_name.replace("&#39;", "\'")

    state.push({
      stoppoint_id: v.stoppoint_id,
      stoparea_id: v.stoparea_id,
      stoparea_kind: v.stoparea_kind,
      user_objectid: v.user_objectid,
      short_name: v.short_name ? v.short_name.replace("&#39;", "\'") : '',
      area_type: v.area_type,
      index: i,
      edit: false,
      city_name: v.city_name ? v.city_name.replace("&#39;", "\'") : '',
      zip_code: v.zip_code,
      name: v.name ? v.name.replace("&#39;", "\'") : '',
      registration_number: v.registration_number,
      stop_area_referential_id: v.stop_area_referential_id,
      text: fancyText,
      for_boarding: v.for_boarding,
      for_alighting: v.for_alighting,
      longitude: v.longitude || 0,
      latitude: v.latitude || 0,
      comment: v.comment ? v.comment.replace("&#39;", "\'") : '',
      olMap: {
        isOpened: false,
        json: {}
      }
    })
  })

  return state
}

var initialState = { stopPoints: getInitialState() }
let store = null

if(Object.assign){
  const loggerMiddleware = createLogger()
  store = createStore(
   reducers,
   initialState,
   applyMiddleware(thunkMiddleware, promise, loggerMiddleware)
 )
}
else{
  // IE
  store = createStore(
   reducers,
   initialState,
   applyMiddleware(thunkMiddleware, promise)
 )
}


render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById('stop_points')
)

document.querySelector('input[name=commit]').addEventListener('click', (event) => {
  let formHelper = new RouteFormHelper({
    inputIds: [
      '#route_name',
      '#route_published_name'
    ],
    stopPoints: store.getState().stopPoints
  })
  formHelper.handleSubmit(event)
})
