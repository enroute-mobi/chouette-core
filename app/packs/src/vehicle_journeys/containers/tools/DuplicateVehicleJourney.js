import actions from '../../actions'
import { connect } from 'react-redux'
import DuplicateVJComponent from '../../components/tools/DuplicateVehicleJourney'

const mapStateToProps = (state, ownProps) => {
  return {
    disabled: ownProps.disabled,
    modal: state.modal,
    vehicleJourneys: state.vehicleJourneys,
    status: state.status,
    filters: state.filters
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalClose: () =>{
      dispatch(actions.closeModal())
    },
    onOpenDuplicateModal: () =>{
      dispatch(actions.openDuplicateModal())
    },
    onDuplicateVehicleJourney: (addtionalTime, duplicateNumber, departureDelta) =>{
      dispatch(actions.duplicateVehicleJourney(addtionalTime, duplicateNumber, departureDelta))
    }
  }
}

const DuplicateVehicleJourney = connect(mapStateToProps, mapDispatchToProps)(DuplicateVJComponent)

export default DuplicateVehicleJourney
