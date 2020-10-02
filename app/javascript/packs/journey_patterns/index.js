import '../../helpers/polyfills'

// react
import React, { useState, useEffect } from 'react';

// openlayers
import GeoJSON from 'ol/format/GeoJSON'
import KML from 'ol/format/KML';
import Feature from 'ol/Feature';
import VectorSource from 'ol/source/Vector'

// components
import MapWrapper from '../../journey_patterns/components/tools/MapWrapper'

import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'
import journeyPatternsApp from '../../journey_patterns/reducers'
import App from '../../journey_patterns/components/App'
import clone from '../../helpers/clone'

import RoutesMap from '../../helpers/routes_map'

let route_kml_url = clone(window, "route_kml_url", true)
let route = clone(window, "route", true)
route = JSON.parse(decodeURIComponent(route))

function RouteMap() {

  // set intial state
  const [ features, setFeatures ] = useState([])

  // initialization - retrieve GeoJSON features from Mock JSON API get features from mock
  //  GeoJson API (read from flat .json file in public directory)
  useEffect( () => {

    fetch(route_kml_url)
      .then(response => response.text())
      .then( (fetchedFeatures) => {

        // parse fetched geojson into OpenLayers features
        //  use options to convert feature from EPSG:4326 to EPSG:3857
        const wktOptions = {
          dataProjection: 'EPSG:4326',
          featureProjection: 'EPSG:3857'
        }
        const parsedFeatures = new KML().readFeatures(fetchedFeatures, wktOptions)
        console.log(parsedFeatures)
        // set features into state (which will be passed into OpenLayers
        //  map component as props)
        setFeatures(parsedFeatures)

      })

  },[])

  return (
    <div className="openlayers_map">
      <MapWrapper features={features} />
    </div>
  )
}

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
);

render(
  <React.StrictMode>
    <RouteMap />
  </React.StrictMode>,
  document.getElementById('route_map')
);
