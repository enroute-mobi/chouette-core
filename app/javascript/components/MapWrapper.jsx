import React, { useState, useEffect, useRef } from 'react'
import { Map, View } from 'ol'
import { Tile as TileLayer, Vector as VectorLayer } from 'ol/layer'
import { OSM, Vector as VectorSource } from 'ol/source'
import { defaults as defaultControls } from 'ol/control'

import { toStringXY } from 'ol/coordinate'
function MapWrapper({ features, onInit, _style }) {
  const [ map, setMap ] = useState()
  const [ featuresLayer, setFeaturesLayer ] = useState()
  const [ selectedCoord , setSelectedCoord ] = useState()

  // pull refs
  const mapElement = useRef()

  // create state ref that can be accessed in OpenLayers onclick callback function
  //  https://stackoverflow.com/a/60643670
  const mapRef = useRef()
  mapRef.current = map

  // initialize map on first render - logic formerly put into componentDidMount
  useEffect( () => {

    // create and add vector source layer
    const initialFeaturesLayer = new VectorLayer({
      source: new VectorSource(),
    })

    // create map
    const initialMap = new Map({
      target: mapElement.current,
      layers: [
        // OSM Topo
        new TileLayer({
          source: new OSM({attributions: '&copy; OpenStreetMap contributors'})
        }),
        initialFeaturesLayer
      ],
      view: new View({
        projection: 'EPSG:3857',
        center: [0, 0],
        minZoom: 10,
        maxZoom: 20
      }),
      controls: defaultControls()
    })

    // set map onclick handler
    // initialMap.on('click', handleMapClick)

    // save map and vector layer references to state
    setMap(initialMap)
    setFeaturesLayer(initialFeaturesLayer)

    onInit(initialMap)
  },[])

  // update map if features prop changes - logic formerly put into componentDidUpdate
  useEffect( () => {

    if (features) { // may be empty on first render

      // set features to map
      featuresLayer.setSource(
        new VectorSource({ features }) // make sure features is an array
      )

      // Workaround to prevent openlayer rendering bugs within modal
      map.updateSize()

      // Fit map to feature extent (with 100px of padding)
      map.getView().fit(featuresLayer.getSource().getExtent(), {
        padding: [100,100,100,100]
      })
    }
  },[features])

  // // map click handler
  // const handleMapClick = (event) => {
  //   // get clicked coordinate using mapRef to access current React state inside OpenLayers callback
  //   //  https://stackoverflow.com/a/60643670
  //   const clickedCoord = mapRef.current.getCoordinateFromPixel(event.pixel)
  //
  //   // transform coord to EPSG 4326 standard Lat Long
  //   const transormedCoord = transform(clickedCoord, 'EPSG:3857', 'EPSG:4326')
  //
  //   // set React state
  //   setSelectedCoord( transormedCoord )
  // }

  // render component
  return (
    <div>
      <div ref={mapElement} className="map-container"></div>
      <div className="clicked-coord-label">
        <p>{ (selectedCoord) ? toStringXY(selectedCoord, 5) : '' }</p>
      </div>
    </div>
  )
}

MapWrapper.defaultProps = {
  onInit: _map => {}
}

export default MapWrapper
