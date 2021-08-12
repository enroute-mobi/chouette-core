import actions from '../../actions'
import { connect } from 'react-redux'
import ConstraintExclusionEditVehicleJourneyComponent from '../../components/tools/ConstraintExclusionEditVehicleJourney'

const mapStateToProps = (state, ownProps) => {
  return {
    editMode: state.editMode,
    modal: state.modal,
    vehicleJourneys: state.vehicleJourneys,
    status: state.status,
    disabled: ownProps.disabled
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalClose: () =>{
      dispatch(actions.closeModal())
    },
    onOpenCalendarsEditModal: (vehicleJourneys) =>{
      dispatch(actions.openConstraintExclusionEditModal(vehicleJourneys))
    },
    onDeleteConstraintZone: (constraint_zone) => {
      dispatch(actions.deleteConstraintZone(constraint_zone))
    },
    onDeleteStopAreasConstraint: (constraint_zone) => {
      dispatch(actions.deleteStopAreasConstraint(constraint_zone))
    },
    onConstraintZonesEditVehicleJourney: (vehicleJourneys, constraint_zones, stop_areas_constraints) => {
      dispatch(actions.editVehicleJourneyConstraintZones(vehicleJourneys, constraint_zones, stop_areas_constraints))
    },
    onSelectConstraintZone: (e) => {
      dispatch(actions.selectConstraintZone(e.params.data))
    },
    onSelectStopAreasConstraint: (e) => {
      dispatch(actions.selectStopAreasConstraint(e.params.data))
    },
  }
}

const ConstraintExclusionEditVehicleJourney = connect(mapStateToProps, mapDispatchToProps)(ConstraintExclusionEditVehicleJourneyComponent)

export default ConstraintExclusionEditVehicleJourney
