import React, { useReducer } from 'react'

import { reducer, initialState } from '../shape.reducer'
import { setAttributes } from '../shape.actions'
import { getSortedWaypoints } from '../shape.selectors'

import useCombineController from '../controllers'
import { useMapInteractions } from '../controllers/ui'
import { useJourneyPatternGeoJSON, useLineFeatureUpdate } from '../controllers/data'

import MapWrapper from '../../../components/MapWrapper'
import List from './List'
import Select from './Select'

export default function ShapeEditorMap() {
  // set intial state
  const [state, dispatch] = useReducer(reducer, initialState)

  // Selectors
  const sortedWaypoints = getSortedWaypoints(state)

  // Helpers
  const setJourneyPatternId = journeyPatternId => {
    dispatch(setAttributes({ journeyPatternId }))
  }

  // Evvent Handlers
  const onMapInit = (map, featuresLayer) => {
    dispatch(setAttributes({ map, featuresLayer }))
  }

  // Controllers
  useCombineController(state, dispatch)(
    useMapInteractions,
    useJourneyPatternGeoJSON,
    useLineFeatureUpdate
  )

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
              <MapWrapper features={state.features} style={state.style} onInit={onMapInit} />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}