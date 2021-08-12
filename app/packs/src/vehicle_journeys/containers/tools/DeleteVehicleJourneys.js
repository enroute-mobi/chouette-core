import actions from '../../actions'
import { connect } from 'react-redux'
import DeleteVJComponent from '../../components/tools/DeleteVehicleJourneys'

const mapStateToProps = (state, ownProps) => {
  return {
    disabled: ownProps.disabled,
    vehicleJourneys: state.vehicleJourneys
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onDeleteVehicleJourneys: () =>{
      dispatch(actions.deleteVehicleJourneys())
    },
  }
}

const DeleteVehicleJourneys = connect(mapStateToProps, mapDispatchToProps)(DeleteVJComponent)

export default DeleteVehicleJourneys
