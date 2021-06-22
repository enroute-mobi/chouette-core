import React, { useReducer } from 'react'

import { reducer, initialState, actions, selectors } from '../shape.reducer'

import { useJourneyPatternGeoJSON, useLineFeatureUpdate } from '../hooks/data'

import { useMapInteractions } from '../hooks/ui'

import MapWrapper from '../../../components/MapWrapper'
import List from './List'
import Select from './Select'

export default function ShapeEditorMap() {
  // set intial state
  const [state, dispatch] = useReducer(reducer, initialState)

  // Selectors
  const sortedWaypoints = selectors.getSortedWaypoints(state)

  // Helpers
  const setJourneyPatternId = journeyPatternId => {
    dispatch(actions.setAttributes({ journeyPatternId }))
  }

  // Handlers
  const handleMapInit = (map, featuresLayer) => {
    dispatch(actions.setAttributes({ map, featuresLayer }))
  }

  // UI
  useMapInteractions(state, dispatch)

  // Data Fetching
  useJourneyPatternGeoJSON(state, dispatch)
  useLineFeatureUpdate(state, dispatch)

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