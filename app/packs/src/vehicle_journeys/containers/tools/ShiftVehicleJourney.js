import actions from '../../actions'
import { connect } from 'react-redux'
import ShiftVJComponent from '../../components/tools/ShiftVehicleJourney'

const mapStateToProps = (state, ownProps) => {
  return {
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
    onOpenShiftModal: () =>{
      dispatch(actions.openShiftModal())
    },
    onShiftVehicleJourney: (data) =>{
      dispatch(actions.shiftVehicleJourney(data))
    }
  }
}

const ShiftVehicleJourney = connect(mapStateToProps, mapDispatchToProps)(ShiftVJComponent)

export default ShiftVehicleJourney
