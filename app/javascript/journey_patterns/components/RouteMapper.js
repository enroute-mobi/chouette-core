// react
import React, { useState, useEffect } from 'react';

// openlayers
import GeoJSON from 'ol/format/GeoJSON'
import KML from 'ol/format/KML';
import Feature from 'ol/Feature';
import VectorSource from 'ol/source/Vector'
import clone from '../../helpers/clone'

// components
import MapWrapper from '../../journey_patterns/components/tools/MapWrapper'

function RouteMapper() {

  // set intial state
  const [ features, setFeatures ] = useState([])
  let route_kml_url = clone(window, "route_kml_url")

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

export default RouteMapper
