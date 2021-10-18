import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../actions'
import AddVehicleJourney from '../containers/tools/AddVehicleJourney'
import DeleteVehicleJourneys from '../containers/tools/DeleteVehicleJourneys'
import SelectVehicleJourneys from '../containers/tools/SelectVehicleJourneys'
import CopyButton from '../containers/tools/CopyButton'
import PasteButton from '../containers/tools/PasteButton'
import ShiftVehicleJourney from '../containers/tools/ShiftVehicleJourney'
import SelectSpecificStop from '../containers/tools/SelectSpecificStop'
import DuplicateVehicleJourney from '../containers/tools/DuplicateVehicleJourney'
import EditVehicleJourney from '../containers/tools/EditVehicleJourney'
import NotesEditVehicleJourney from '../containers/tools/NotesEditVehicleJourney'
import TimetablesEditVehicleJourney from '../containers/tools/TimetablesEditVehicleJourney'
import ConstraintExclusionEditVehicleJourney from '../containers/tools/ConstraintExclusionEditVehicleJourney'


export default class Tools extends Component {
  constructor(props) {
    super(props)
    this.hasPolicy = this.hasPolicy.bind(this)
    this.hasFeature = this.hasFeature.bind(this)
    this.hasDeletedVJ = this.hasDeletedVJ.bind(this)
  }

  hasPolicy(key) {
    // Check if the user has the policy to disable or not the action
    return this.props.filters.policy[`vehicle_journeys.${key}`]
  }

  hasFeature(key) {
    // Check if the organisation has the given feature
    return this.props.filters.features[key]
  }

  hasDeletedVJ() {
    return actions.getSelectedDeletables(this.props.vehicleJourneys).length > 0
  }

  render() {
    let { hasPolicy, hasFeature, hasDeletedVJ, props: { vehicleJourneys, onCancelSelection, onCancelDeletion, editMode, selectionMode, selection, toggleArrivals } } = this
    return (
      <div className='select_toolbox'>
        <ul>
          { !selectionMode && <AddVehicleJourney disabled={!hasPolicy("create") || !editMode} /> }
          { !selectionMode && <DuplicateVehicleJourney disabled={!hasPolicy("create") || !hasPolicy("update") || !editMode || hasDeletedVJ()}/> }
          { !selectionMode && <ShiftVehicleJourney disabled={!hasPolicy("update") || !editMode || hasDeletedVJ()}/> }
          { !selectionMode && <SelectSpecificStop disabled={hasDeletedVJ()}/> }
          { !selectionMode && <EditVehicleJourney disabled={hasDeletedVJ()}/> }

          { !selectionMode && <TimetablesEditVehicleJourney disabled={hasDeletedVJ()}/> }
          { !selectionMode && hasFeature('routing_constraint_zone_exclusion_in_vehicle_journey') &&
            <ConstraintExclusionEditVehicleJourney disabled={hasDeletedVJ()} stopAreasConstraints={hasFeature('stop_area_routing_constraints')} />
          }
          { !selectionMode && <NotesEditVehicleJourney disabled={hasDeletedVJ()}/> }
          { !selectionMode && <DeleteVehicleJourneys disabled={!hasPolicy("destroy") || !editMode || hasDeletedVJ()}/> }
          { selectionMode && <CopyButton disabled={!selection.locked} toggleArrivals={toggleArrivals} /> }
          { selectionMode && <PasteButton disabled={ !selection.locked } />  }
          <SelectVehicleJourneys disabled={!editMode}/>
        </ul>
        { !selectionMode && <div>
          <div className='pull-left'>
            <span className='info-msg left-span'>{I18n.t('vehicle_journeys.vehicle_journeys_matrix.selected_journeys', { count: actions.getSelected(vehicleJourneys).length })}</span>
          </div>
          <button className='btn btn-xs btn-link'
                  disabled={actions.getSelected(vehicleJourneys).length == 0}
                  onClick={onCancelSelection}>
                  {I18n.t('vehicle_journeys.vehicle_journeys_matrix.cancel_selection')}
          </button>
          <button className='btn btn-xs btn-link pull-right'
                  disabled={actions.getSelectedDeletables(vehicleJourneys).length == 0}
                  onClick={onCancelDeletion}>
                  {I18n.t('vehicle_journeys.vehicle_journeys_matrix.cancel_destroy')}
          </button>
        </div>
      }
      </div>
    )
  }
}

Tools.propTypes = {
  vehicleJourneys : PropTypes.array.isRequired,
  onCancelSelection: PropTypes.func.isRequired,
  filters: PropTypes.object.isRequired
}
