import React from 'react'
import { render } from 'react-dom'
import { Provider } from 'react-redux'
import { createStore } from 'redux'
import applyMiddleware from '../../src/helpers/middlewares'
import journeyPatternsApp from '../../src/journey_patterns/reducers'
import App from '../../src/journey_patterns/components/App'
import clone from '../../src/helpers/clone'

import {Fill, Stroke, Circle, Style} from 'ol/style'
import GeometryType from 'ol/geom/GeometryType'

let route = clone(window, "route", true)
route = JSON.parse(decodeURIComponent(route))

function RouteMap() {
  // set intial state
  const [ features, setFeatures ] = useState([])
  const [ style, setStyle ] = useState(new Style({}))

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

        var style = new Style({
          image: new Circle({
            radius: 10,
            fill: new Fill({
              color: 'rgba(255, 153, 0)',
            }),
            stroke: new Stroke({
              color: 'rgba(255, 204, 0)',
              width: 4,
            }),
          }),
          stroke: new Stroke({
            color: 'rgba(255, 204, 0)',
            width: 4,
          }),
          fill: new Fill({
            color: 'rgba(255, 153, 0)',
          }),

        })

        const parsedFeatures = new KML({extractStyles: false, defaultStyle: style} ).readFeatures(fetchedFeatures, wktOptions)

        // set features into state (which will be passed into OpenLayers
        //  map component as props)
        setFeatures(parsedFeatures)

      })

  },[])

  return (
    <div className="openlayers_map">
      <MapWrapper features={features} style={style} />
    </div>
  )
}

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

let store = createStore(
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
