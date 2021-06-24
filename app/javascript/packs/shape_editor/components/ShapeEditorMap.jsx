import React from 'react'
import { pick } from 'lodash'

import { getSortedWaypoints } from '../shape.selectors'

import store from '../shape.store'
import { useStore } from '../../../helpers/hooks'

import combineControllers from '../controllers'
import { useMapController } from '../controllers/ui'
import { useJourneyPatternController, useLineController } from '../controllers/data'

import MapWrapper from '../../../components/MapWrapper'
import List from './List'
import Select from './Select'

const mapStateToProps = state => ({
  ...pick(state, ['features', 'setAttributes', 'style']),
  waypoints: getSortedWaypoints(state)
})

export default function ShapeEditorMap() {
  // Store
  const [
    { features, setAttributes, style, waypoints }
  ] = useStore(store, mapStateToProps)
  // Evvent Handlers
  const onMapInit = (map, featuresLayer) => setAttributes({ map, featuresLayer })

  // Controllers
  combineControllers(store)(
    useMapController,
    useJourneyPatternController,
    useLineController
  )

  return (
    <div className="page-content">
      <div className="container-fluid">
        <div className="row">
          <Select />
        </div>
        <div className="row">
          <div className="col-md-6">
            <h4 className="underline">Liste</h4>
            <List waypoints={waypoints} />
          </div>
          <div className="col-md-6">
            <h4 className="underline">Carte</h4>
            <div className="openlayers_map">
              <MapWrapper features={features} style={style} onInit={onMapInit} />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}