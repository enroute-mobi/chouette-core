import React, { useEffect, useReducer, useState } from 'react'
import { isEmpty } from 'lodash'
import Rails from "@rails/ujs"

import { Fill, Stroke, Circle, Style } from 'ol/style'
import KML from 'ol/format/KML'
import GeoJSON from 'ol/format/GeoJSON'
import Collection from 'ol/Collection'
import Modify from 'ol/interaction/Modify'
import Draw from 'ol/interaction/Draw'
import Snap from 'ol/interaction/Snap'

import { reducer, initialState, actions, selectors } from '../shape.reducer'
import MapWrapper from '../../../components/MapWrapper'
import List from './List'

// parse fetched geojson into OpenLayers features
//  use options to convert feature from EPSG:4326 to EPSG:3857
const wktOptions = {
  dataProjection: 'EPSG:4326',
  featureProjection: 'EPSG:3857'
}

const defaultStyle = new Style({
  image: new Circle({
    radius: 10,
    fill: new Fill({
      color: 'rgba(255, 153, 0)',
    }),
    stroke: new Stroke({
      color: 'rgba(255, 204, 0)',
      width: 10,
    }),
  }),
  stroke: new Stroke({
    color: 'rgba(255, 204, 0)',
    width: 10,
  }),
  fill: new Fill({
    color: 'rgba(255, 153, 0)',
  })
})

export default function ShapeEditorMap() {
  // set intial state
  const [state, dispatch] = useReducer(reducer, initialState)
  const [shouldUpdateLine, setShouldUpdateLine] = useState(false)

  const sortedWaypoints = selectors.getSortedWaypoints(state)
  const sortedCoordinates = selectors.getSortedCoordinates(state)

  // Handlers
  const handleMapInit = async (map, featuresLayer) => {
    const response = await fetch('/shape_editor/get_waypoints')
    const fetchedFeatures = await response.text()

    const features = new KML({ extractStyles: false, defaultStyle }).readFeatures(fetchedFeatures, wktOptions) // TODO use GeoJSON format instead of KML
    const line = features.find(f => f.getGeometry().getType() == 'LineString')
    const waypoints = features.filter(f => f.getGeometry().getType() == 'Point')

    dispatch(actions.setLine(line))
    dispatch(actions.setWaypoints(waypoints))

    dispatch(actions.setAttributes({ map, featuresLayer, features }))
  }

  const handleNewPoint = e => {
    dispatch(actions.addNewPoint(e.feature))
    triggerShouldUpdateLine()
  }

  const handleMovePoint = e => {
    dispatch(actions.setWaypoints(e.features.getArray()))
    triggerShouldUpdateLine()
  }

  const handleLineUpdate = () => {
    Rails.ajax({
      type: 'PUT',
      url: '/shape_editor/update_line',
      data: JSON.stringify({ coordinates: sortedCoordinates }),
      dataType: 'json',
      success: data => {
        const lineFeature = new GeoJSON().readFeature(data, wktOptions)
        const source = getSource()

        lineFeature.setId('line')

        source.removeFeature(
          source.getFeatureById('line')
        )

        source.addFeature(lineFeature)

        dispatch(actions.setLine(lineFeature))
      },
      error: response => console.warn('error', response)
    })
  }

  // Helpers
  const hasWaypoints = () => !isEmpty(state.waypoints)
  const getSource = () => state.featuresLayer?.getSource()
  const triggerShouldUpdateLine = () => {
    setShouldUpdateLine(true)
    setShouldUpdateLine(false)
  }

  // useEffect hooks
  useEffect(() => {
    if (!!state.featuresLayer && hasWaypoints()) {
      const source = state.featuresLayer.getSource()
      const modify = new Modify({ features: new Collection(state.waypoints) })
      const draw = new Draw({ source, type: 'Point' })
      const snap = new Snap({ source })
      const interactions = [modify, draw, snap]

      interactions.forEach(i => state.map.addInteraction(i))

      dispatch(actions.setAttributes({ draw, modify, snap }))
    }
  }, [state.featuresLayer, state.waypoints])

  useEffect(() => {
    !!state.draw && state.draw.on('drawend', handleNewPoint)
  }, [state.draw])

  useEffect(() => {
    !!state.modify && state.modify.on('modifyend', handleMovePoint)
  }, [state.modify])

  useEffect(() => {
    shouldUpdateLine && handleLineUpdate()
  }, [shouldUpdateLine])

  return (
    <div className="page-content">
      <div className="container-fluid">
        <div className="row">
          <div className="col-md-6">
            <h4 className="underline">Liste</h4>
            <List waypoints={sortedWaypoints} />
          </div>
          <div className="col-md-6">
            <h4 className="underline">Carte</h4>
            <div className="openlayers_map">
              <MapWrapper features={state.features} style={state.style} onInit={handleMapInit} />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}