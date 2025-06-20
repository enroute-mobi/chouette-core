import React, { useMemo, useEffect, useCallback, useState, useRef } from 'react'
import { PropTypes } from 'prop-types'
import { Map, View } from 'ol'
import { Tile as TileLayer, Vector as VectorLayer } from 'ol/layer'
import { OSM, Vector as VectorSource } from 'ol/source'
import { ScaleLine, Zoom, ZoomSlider } from 'ol/control'
import { toStringXY } from 'ol/coordinate'

import { toWgs84 } from '@turf/turf'

import { usePrevious } from '../helpers/hooks'

function MapWrapper({ features, onInit, style, height, width }) {
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
        new TileLayer({ source: new OSM({ attributions: '&copy; OpenStreetMap contributors' }) }),
        featuresLayer
      ],
      view: new View({ center: [0, 0], zoom: 2 }),
      controls: [new ScaleLine(), new Zoom(), new ZoomSlider()]
    }),
    []
  )

  // pull refs
  const mapRef = useRef(null)

  useEffect(() => {
    if (mapRef.current) {
      map.setTarget(mapRef.current)
      
      // Forcer l'updateSize après un court délai pour s'assurer que la modal est visible
      setTimeout(() => {
        map.updateSize()
        if (features && features.length > 0) {
          map.getView().fit(featuresLayer.getSource().getExtent(), {
            padding: [100, 100, 100, 100],
            maxZoom: 18
          })
        }
      }, 100)

      // Observer les changements de taille
      const observer = new ResizeObserver(() => {
        map.updateSize()
        if (features && features.length > 0) {
          map.getView().fit(featuresLayer.getSource().getExtent(), {
            padding: [100, 100, 100, 100],
            maxZoom: 18
          })
        }
      })

      observer.observe(mapRef.current)

      return () => {
        observer.unobserve(mapRef.current)
      }
    }
  }, [mapRef, map, features, featuresLayer])

  useEffect(() => {
    map.on('singleclick', e => { setSelectedCoord(toWgs84(e.coordinate)) })
    onInit(map)
  },[])

  // update map if features prop changes - logic formerly put into componentDidUpdate
  useEffect( () => {
    if (features && !previousFeatures) { // we just want to execute this block once

      // set features to map
      featuresLayer.setSource(new VectorSource({ features }))

      // Workaround to prevent openlayer rendering bugs within modal
      map.updateSize()

      // Fit map to feature extent (with 100px of padding)
      map.getView().fit(featuresLayer.getSource().getExtent(), {
        padding: [100,100,100,100],
        maxZoom: 18
      })
    }
  },[features])

  // render component
  return (
    <div>
      <div ref={mapRef} className="map-container" style={{ width, height }}></div>
      <div className="clicked-coord-label">
        <p>{ (selectedCoord) ? toStringXY(selectedCoord, 5) : '' }</p>
      </div>
    </div>
  )
}

MapWrapper.defaultProps = {
  onInit: _map => {},
  height: 370,
  width: '100%'
}

MapWrapper.propTypes = {
  fetchFeatures: PropTypes.array,
  onInit: PropTypes.func,
  style: PropTypes.object,
  height: PropTypes.number,
  width: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
}

export default MapWrapper
