import React, { useState, useEffect, useRef } from 'react'

import Map from 'ol/Map'
import View from 'ol/View'
import OSM from 'ol/source/OSM'
import TileLayer from 'ol/layer/Tile'
import VectorLayer from 'ol/layer/Vector'
import KML from 'ol/format/KML'
import {Control, defaults as defaultControls} from 'ol/control'
import VectorSource from 'ol/source/Vector'
import XYZ from 'ol/source/XYZ'
import {transform} from 'ol/proj'
import {toStringXY} from 'ol/coordinate'
import { Fill, Stroke, Circle, Style } from 'ol/style'
import Modify from 'ol/interaction/Modify';
import Draw from 'ol/interaction/Draw';
import Snap from 'ol/interaction/Snap';

function ShapeEditor(props) {

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
        zoom: 2
      }),
      controls: defaultControls()
    })

    // set map onclick handler
    // initialMap.on('click', handleMapClick)

    // save map and vector layer references to state
    setMap(initialMap)
    setFeaturesLayer(initialFeaturesLayer)
  },[])

  // update map if features prop changes - logic formerly put into componentDidUpdate
  useEffect(() => {

    // const vector = new VectorLayer({
    //   source: source,
    //   style: new Style({
    //     fill: new Fill({
    //       color: 'rgba(255, 255, 255, 0.2)',
    //     }),
    //     stroke: new Stroke({
    //       color: '#ffcc33',
    //       width: 10,
    //     })
    //   }),
    // });

    if (props.features.length) { // may be null on first render
      const source = new VectorSource({
        features: props.features // make sure features is an array
      })
      // set features to map
      featuresLayer.setSource(source)
        const modify = new Modify({source: source});
        const draw = new Draw({
          source: source,
          type: 'LineString',
        });
        map.addInteraction(draw);
        const snap = new Snap({source: source});
        map.addInteraction(snap);
        map.addInteraction(modify);
        // Workaround to prevent openlayer rendering bugs within modal
        map.updateSize()

        // Fit map to feature extent (with 100px of padding)
        map.getView().fit(featuresLayer.getSource().getExtent(), {
          padding: [100,100,100,100]
        })
    }
  },[props.features])

  // // map click handler
  const handleMapClick = (event) => {
    // get clicked coordinate using mapRef to access current React state inside OpenLayers callback
    //  https://stackoverflow.com/a/60643670
    const clickedCoord = mapRef.current.getCoordinateFromPixel(event.pixel)

    // transform coord to EPSG 4326 standard Lat Long
    const transormedCoord = transform(clickedCoord, 'EPSG:3857', 'EPSG:4326')

    // set React state
    setSelectedCoord( transormedCoord )
  }

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

export default ShapeEditor
