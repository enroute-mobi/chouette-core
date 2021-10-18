import React, { useState, useEffect } from 'react'

import KML from 'ol/format/KML'
import clone from '../../helpers/clone'

import MapWrapper from '../../components/MapWrapper'
import routeMapStyle from '../../helpers/routeMapStyle'

function RouteMap() {

  // set intial state
  const [ features, setFeatures ] = useState([])
  let route_kml_url = clone(window, "route_kml_url")
  let lineColor = clone(window, "lineColor")

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

        var style = routeMapStyle({strokeColor: lineColor})
        const parsedFeatures = new KML({defaultStyle: style}).readFeatures(fetchedFeatures, wktOptions)

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

export default RouteMap
