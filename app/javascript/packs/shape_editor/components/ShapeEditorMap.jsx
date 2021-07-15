import React from 'react'
import { pick } from 'lodash'

import { getSortedWaypoints } from '../shape.selectors'

import store from '../shape.store'
import { useStore } from '../../../helpers/hooks'

import { useMapController, useValidatorController } from '../controllers/ui'
import {
  useJourneyPatternController,
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
  const onMapInit = (map, featuresLayer) => store.setAttributes({ map, featuresLayer })

  // Controllers
  useMapController()
  useValidatorController()

  useJourneyPatternController(isEdit, baseURL)
  useLineController(baseURL)
  useUserPermissionsController(baseURL)
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
  )
}