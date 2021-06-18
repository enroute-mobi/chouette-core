import React, { useContext, useEffect, useReducer, useState } from 'react'
import { isEmpty } from 'lodash'
import Rails from "@rails/ujs"

import GeoJSON from 'ol/format/GeoJSON'
import Collection from 'ol/Collection'
import Modify from 'ol/interaction/Modify'
import Draw from 'ol/interaction/Draw'
import Snap from 'ol/interaction/Snap'

import { ShapeContext } from '../shape.context'
import { reducer, initialState, actions, selectors } from '../shape.reducer'
import MapWrapper from '../../../components/MapWrapper'
import List from './List'
import Select from './Select'

export default function ShapeEditorMap() {
  // set intial state
  const [state, dispatch] = useReducer(reducer, initialState)
  const [shouldUpdateLine, setShouldUpdateLine] = useState(false)

  const { baseURL, lineId, wktOptions } = useContext(ShapeContext)

  const sortedWaypoints = selectors.getSortedWaypoints(state)
  const sortedCoordinates = selectors.getSortedCoordinates(state)

  // Handlers
  const handleMapInit = async (map, featuresLayer) => {
    dispatch(actions.setAttributes({ map, featuresLayer }))
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
      url: `${baseURL}/shape_editor/update_line`,
      data: JSON.stringify({ coordinates: sortedCoordinates }),
      dataType: 'json',
      success: data => {
        const lineFeature = new GeoJSON().readFeature(data, wktOptions)
        const source = getSource()

        lineFeature.setId(lineId)

        source.removeFeature(
          source.getFeatureById(lineId)
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
  const setJourneyPatternId = id => dispatch(actions.setJourneyPatternId(id))

  const fetchWaypoints = async () => {
    const baseURL = window.location.pathname.split('/shape_editor')[0]
    const response = await fetch(`${baseURL}/journey_patterns/${state.journeyPatternId}.geojson`)
    const fetchedFeatures = await response.json()

    const features = new GeoJSON().readFeatures(fetchedFeatures, wktOptions)

    const line = features.find(f => f.getGeometry().getType() == 'LineString')
    const waypoints = features.filter(f => f.getGeometry().getType() == 'Point')

    dispatch(actions.setLine(line))
    dispatch(actions.setWaypoints(waypoints))
    dispatch(actions.setAttributes({ features }))
  }

  // useEffect hooks
  useEffect(() => {
    !!state.featuresLayer &&
    hasWaypoints() &&
    state.featuresLayer.on('change:source', e => {
      const source = e.target.getSource()
      const modify = new Modify({ features: new Collection(state.waypoints) })
      const draw = new Draw({ source, type: 'Point' })
      const snap = new Snap({ source })
      const interactions = [modify, draw, snap]

      interactions.forEach(i => state.map.addInteraction(i))

      dispatch(actions.setAttributes({ draw, modify, snap }))
    })
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

  useEffect(() => {
    !!state.journeyPatternId && fetchWaypoints()
  }, [state.journeyPatternId])

  return (
    <div className="page-content">
      <div className="container-fluid">
        <div className="row">
          <Select setJourneyPatternId={setJourneyPatternId}/>
        </div>
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