import React, { useEffect } from 'react'
import PropTypes from 'prop-types'
import { pick } from 'lodash'

import { getSortedWaypoints } from '../shape.selectors'
import store from '../shape.store'
import eventEmitter from '../shape.event-emitter'
import { onAddPoint$, onReceiveRouteFeatures$, onReceiveShapeFeatures$, onWaypointsUpdate$ } from '../shape.observables'

import { useStore } from '../../../helpers/hooks'

import { useMapController, useValidatorController } from '../controllers/ui'
import {
  useRouteController,
  useLineController,
  useShapeController,
  useUserPermissionsController
} from '../controllers/data'

import MapWrapper from '../../../components/MapWrapper'
import NameInput from './NameInput'
import List from './List'
import CancelButton from './CancelButton'
import SaveButton from './SaveButton'

const mapStateToProps = state => ({
  ...pick(state, ['name', 'permissions', 'style']),
  features: Array.from(state.shapeFeatures.getArray()),
  waypoints: getSortedWaypoints(state)
})
export default function ShapeEditorMap({ isEdit, baseURL, redirectURL }) {
  // Store
  const { features, name, permissions, style, waypoints } = useStore(store, mapStateToProps)

  // Evvent Handlers
  const onMapInit = map => setTimeout(() => eventEmitter.emit('map:init', map), 0) // Need to do this to ensure that controllers can subscribe to event before it is fired
  const onWaypointZoom = waypoint => eventEmitter.emit('map:zoom-to-waypoint', waypoint)
  const onDeleteWaypoint = waypoint => eventEmitter.emit('map:delete-waypoint-request', waypoint)
  const onSubmit = _event => eventEmitter.emit('shape:submit')
  const onConfirmCancel = _event => window.location.replace(redirectURL)

  // Controllers
  useMapController()
  useValidatorController()

  useRouteController(isEdit)
  useLineController(isEdit, baseURL)
  useUserPermissionsController(isEdit, baseURL)
  useShapeController(isEdit, baseURL)

  useEffect(() => {
    onAddPoint$.subscribe(event => eventEmitter.emit('map:add-point', event))
    onReceiveRouteFeatures$.subscribe(event => eventEmitter.emit('route:receive-features', event))
    onReceiveShapeFeatures$.subscribe(event => eventEmitter.emit('shape:receive-features', event))
    onWaypointsUpdate$.subscribe(_state => eventEmitter.emit('waypoints:updated'))

    return () => {
      eventEmitter.complete()
    }
  }, [])

  return (
    <div>
      <CancelButton onConfirmCancel={onConfirmCancel} />
      <SaveButton isEdit={isEdit} permissions={permissions} onSubmit={onSubmit} />
      <div className="row">
        <NameInput name={name} /> 
      </div>
      <div className="row">
        <div className="col-md-6">
          <h4 className="underline">Liste</h4>
          <List waypoints={waypoints} onWaypointZoom={onWaypointZoom} onDeleteWaypoint={onDeleteWaypoint} />
        </div>
        <div className="col-md-6">
          <h4 className="underline">Carte</h4>
          <div className="openlayers_map">
            <MapWrapper features={features} style={style} onInit={onMapInit} />
          </div>
        </div>
      </div>
    </div>
  )
}

ShapeEditorMap.propTypes = {
  isEdit: PropTypes.bool.isRequired,
  baseURL: PropTypes.string.isRequired,
  redirectURL: PropTypes.string.isRequired,
}