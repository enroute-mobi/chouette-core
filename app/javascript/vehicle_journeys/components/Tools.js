import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../actions'
import AddVehicleJourney from '../containers/tools/AddVehicleJourney'
import DeleteVehicleJourneys from '../containers/tools/DeleteVehicleJourneys'
import ShiftVehicleJourney from '../containers/tools/ShiftVehicleJourney'
import DuplicateVehicleJourney from '../containers/tools/DuplicateVehicleJourney'
import EditVehicleJourney from '../containers/tools/EditVehicleJourney'
import NotesEditVehicleJourney from '../containers/tools/NotesEditVehicleJourney'
import TimetablesEditVehicleJourney from '../containers/tools/TimetablesEditVehicleJourney'
import PurchaseWindowsEditVehicleJourney from '../containers/tools/PurchaseWindowsEditVehicleJourney'
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
    let { hasPolicy, hasFeature, hasDeletedVJ, props: { vehicleJourneys, onCancelSelection, onCancelDeletion, editMode } } = this
    return (
      <div className='select_toolbox'>
        <ul>
          <AddVehicleJourney disabled={!hasPolicy("create") || !editMode} />
          <DuplicateVehicleJourney disabled={!hasPolicy("create") || !hasPolicy("update") || !editMode || hasDeletedVJ()}/>
          <ShiftVehicleJourney disabled={!hasPolicy("update") || !editMode || hasDeletedVJ()}/>
          <EditVehicleJourney disabled={hasDeletedVJ()}/>

          <TimetablesEditVehicleJourney disabled={hasDeletedVJ()}/>
          { hasFeature('purchase_windows') &&
            <PurchaseWindowsEditVehicleJourney disabled={hasDeletedVJ()}/>
          }
          <ConstraintExclusionEditVehicleJourney disabled={hasDeletedVJ()}/>
          <NotesEditVehicleJourney disabled={!hasPolicy("update") || hasDeletedVJ()}/>
          <DeleteVehicleJourneys disabled={!hasPolicy("destroy") || !editMode || hasDeletedVJ()}/>
        </ul>
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
    )
  }
}

Tools.propTypes = {
  vehicleJourneys : PropTypes.array.isRequired,
  onCancelSelection: PropTypes.func.isRequired,
  filters: PropTypes.object.isRequired
}
