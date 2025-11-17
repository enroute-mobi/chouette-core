import React, { useMemo, useEffect, useCallback, useState, useRef } from 'react'
import { PropTypes } from 'prop-types'
import { Map, View } from 'ol'
import { Tile as TileLayer, Vector as VectorLayer } from 'ol/layer'
import { OSM, XYZ, Vector as VectorSource } from 'ol/source'
import { ScaleLine, Zoom, ZoomSlider } from 'ol/control'
import { toStringXY } from 'ol/coordinate'

import { toWgs84 } from '@turf/turf'

import { usePrevious } from '../helpers/hooks'
function MapWrapper({ features, onInit, style, height, width }) {
  const [selectedCoord, setSelectedCoord] = useState()
  const [showSatellite, setShowSatellite] = useState(false)
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
        new TileLayer({
          title: 'Satellite',
          type: 'base',
          visible: false,
          source: new XYZ({
            url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            attributions: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'
          })
        }),
        featuresLayer
      ],
      view: new View({ center: [0, 0], zoom: 2 }),
      controls: [new ScaleLine(), new Zoom(), new ZoomSlider()]
    }),
    []
  )

  // pull refs
  const mapRef = useRef(null)

  const handleMapSizeUpdate = useCallback(() => {
    if (features && features.length > 0) {
      map.updateSize()
      map.getView().fit(featuresLayer.getSource().getExtent(), {
        padding: [100, 100, 100, 100],
        maxZoom: 18
      })
    }
  }, [map, features, featuresLayer])

  useEffect(() => {
    if (mapRef.current) {
      map.setTarget(mapRef.current)

      // Force updateSize after a short delay to ensure modal is visible
      setTimeout(handleMapSizeUpdate, 100)

      // Observe size changes
      const observer = new ResizeObserver(handleMapSizeUpdate)
      observer.observe(mapRef.current)

      return () => {
        observer.unobserve(mapRef.current)
      }
    }
  }, [mapRef, handleMapSizeUpdate])

  useEffect(() => {
    map.on('singleclick', e => { setSelectedCoord(toWgs84(e.coordinate)) })
    onInit(map)
  },[])

  // update map if features prop changes - logic formerly put into componentDidUpdate
  useEffect( () => {
    if (features && !previousFeatures) { // we just want to execute this block once

      // set features to map
      featuresLayer.setSource(new VectorSource({ features }))
    }
  },[features])

  // Switch between layers
  const toggleLayer = useCallback((e) => {
    const isSatellite = e.target.checked
    setShowSatellite(isSatellite)
    map.getLayers().item(0).setVisible(!isSatellite)
    map.getLayers().item(1).setVisible(isSatellite)
  }, [map])

  // render component
  return (
    <div style={{ position: 'relative' }}>
      <div ref={mapRef} className="map-container" style={{ width, height }}></div>
      <div className="clicked-coord-label">
        <p>{selectedCoord ? toStringXY(selectedCoord, 5) : ''}</p>
      </div>
      <div style={{
        position: 'absolute',
        bottom: '10px',
        left: '10px',
        zIndex: 1000,
        backgroundColor: 'white',
        padding: '5px 10px',
        borderRadius: '4px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.2)'
      }}>
        <label style={{ 
          display: 'flex', 
          alignItems: 'center',
          cursor: 'pointer',
          transition: 'background-color 0.2s',
          padding: '2px 5px',
          borderRadius: '3px',
          ':hover': {
            backgroundColor: '#f5f5f5'
          }
        }}>
          <input
            type="checkbox"
            checked={showSatellite}
            onChange={toggleLayer}
            style={{ marginRight: '5px' }}
          />
          {window.I18n.t('maps.satellite_view')}
        </label>
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
