import React, { useMemo, useEffect, useCallback, useState } from 'react'
import { PropTypes } from 'prop-types'
import { Map, View } from 'ol'
import { Tile as TileLayer, Vector as VectorLayer } from 'ol/layer'
import { OSM, Vector as VectorSource } from 'ol/source'
import { ScaleLine, Zoom, ZoomSlider } from 'ol/control'
import { toStringXY } from 'ol/coordinate'

import { toWgs84 } from '@turf/turf'

import { usePrevious } from '../helpers/hooks'

function MapWrapper({ features, onInit, style }) {
  const [ selectedCoord , setSelectedCoord ] = useState()
  const previousFeatures = usePrevious(features)

  const featuresLayer = useMemo(
    () => new VectorLayer({ source: new VectorSource(), style }),
    []
  )

  const map = useMemo(
    () => new Map({
      layers: [
        // OSM Topo
        new TileLayer({
          source: new OSM({ attributions: '&copy; OpenStreetMap contributors' })
        }),
        featuresLayer
      ],
      view: new View({
        projection: 'EPSG:3857',
        center: [0, 0],
        minZoom: 10,
        maxZoom: 20
      }),
      controls: [
        new ScaleLine(),
        new Zoom(),
        new ZoomSlider()
      ]
    }),
    []
  )

  // pull refs
  const mapRef = useCallback(node => {
    if (node !== null) {
      map.setTarget(node)
    }
  }, [])

  // initialize map on first render - logic formerly put into componentDidMount
  useEffect( () => {
    map.on('singleclick', e => {
      setSelectedCoord(
        toWgs84(e.coordinate)
      )
    })
    onInit(map)
  },[])

  // update map if features prop changes - logic formerly put into componentDidUpdate
  useEffect( () => {

    if (features && !previousFeatures) { // we just want to execute this block once

      // set features to map
      featuresLayer.setSource(
        new VectorSource({ features })
      )

      // Workaround to prevent openlayer rendering bugs within modal
      map.updateSize()

      // Fit map to feature extent (with 100px of padding)
      map.getView().fit(featuresLayer.getSource().getExtent(), {
        padding: [100,100,100,100]
      })
    }
  },[features])

  // render component
  return (
    <div>
      <div ref={mapRef} className="map-container"></div>
      <div className="clicked-coord-label">
        <p>{ (selectedCoord) ? toStringXY(selectedCoord, 5) : '' }</p>
      </div>
    </div>
  )
}

MapWrapper.defaultProps = {
  features: PropTypes.array,
  onInit: _map => {}
}

export default MapWrapper
