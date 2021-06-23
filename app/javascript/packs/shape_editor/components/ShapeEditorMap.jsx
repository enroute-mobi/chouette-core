import React, { useReducer } from 'react'

import { reducer, initialState } from '../shape.reducer'
import actionDispatcher from '../shape.actions'
import { getSortedWaypoints } from '../shape.selectors'

import combineControllers from '../controllers'
import { useMapController } from '../controllers/ui'
import { useJourneyPatternController, useLineController } from '../controllers/data'

import MapWrapper from '../../../components/MapWrapper'
import List from './List'
import Select from './Select'

export default function ShapeEditorMap() {
  // Reducer
  const [state, dispatch] = useReducer(reducer, initialState)

  // Action Dispatcher
  const dispatcher = actionDispatcher(dispatch)

  // Selectors
  const sortedWaypoints = getSortedWaypoints(state)

  // Helpers
  const setJourneyPatternId = journeyPatternId => {
    dispatcher.setAttributes({ journeyPatternId })
  }

  // Evvent Handlers
  const onMapInit = (map, featuresLayer) => {
    dispatcher.setAttributes({ map, featuresLayer })
  }

  // Controllers
  combineControllers(state, dispatcher)(
    useMapController,
    useJourneyPatternController,
    useLineController
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