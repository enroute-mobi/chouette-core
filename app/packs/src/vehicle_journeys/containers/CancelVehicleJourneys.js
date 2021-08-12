import { connect } from 'react-redux'
import CancelVehicleJourneysComponent from '../components/CancelVehicleJourneys'

const mapStateToProps = (state) => {
  return {
    editMode: state.editMode,
    status: state.status,
    filters: state.filters
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onConfirmCancel: () => {
      window.location.reload()
    }
  }
}

const CancelVehicleJourneys = connect(mapStateToProps, mapDispatchToProps)(CancelVehicleJourneysComponent)

export default CancelVehicleJourneys
