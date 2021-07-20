import React, { useEffect } from 'react'
import PropTypes from 'prop-types'
import { pick } from 'lodash'

import { getSortedWaypoints } from '../shape.selectors'
import store from '../shape.store'
import eventEmitter from '../shape.event-emitter'
import { onAddPoint$, onMapInit$, onReceiveFeatures$, onWaypointsUpdate$ } from '../shape.observables'

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
  ...pick(state, ['name', 'features', 'permissions', 'style']),
  waypoints: getSortedWaypoints(state)
})
export default function ShapeEditorMap({ isEdit, baseURL }) {
  // Store
  const { features, name, permissions, style, waypoints } = useStore(store, mapStateToProps)

  // Evvent Handlers
  const onMapInit = map => store.setAttributes({ map })
  const onWaypointZoom = waypoint => eventEmitter.emit('map:zoom-to-waypoint', waypoint)
  const onDeleteWaypoint = waypoint => eventEmitter.emit('map:delete-waypoint-request', waypoint)

  useEffect(() => {
    onMapInit$.subscribe(state => eventEmitter.emit('map:init', state.map))
    onAddPoint$.subscribe(event => eventEmitter.emit('map:add-point', event))
    onReceiveFeatures$.subscribe(state => eventEmitter.emit('shape:receive-features', state))
    onWaypointsUpdate$.subscribe(state => eventEmitter.emit('waypoints:updated', state))

    return () => {
      eventEmitter.complete()
    }
  }, [])

  // Controllers
  useMapController()
  useValidatorController()

  useRouteController(isEdit)
  useLineController(isEdit, baseURL)
  useUserPermissionsController(isEdit, baseURL)
  useShapeController(isEdit, baseURL)

  return (
    <div>
      <CancelButton />
      <SaveButton editMode={true} isEdit={isEdit} permissions={permissions} />
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
  baseURL: PropTypes.string.isRequired
}