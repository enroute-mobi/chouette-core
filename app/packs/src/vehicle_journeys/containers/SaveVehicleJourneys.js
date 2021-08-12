import actions from '../actions'
import { connect } from 'react-redux'
import SaveVehicleJourneysComponent from '../components/SaveVehicleJourneys'

const mapStateToProps = (state) => {
  return {
    editMode: state.editMode,
    vehicleJourneys: state.vehicleJourneys,
    page: state.pagination.page,
    status: state.status,
    filters: state.filters
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onEnterEditMode: () => {
      dispatch(actions.enterEditMode())
    },
    onExitEditMode: () => {
      dispatch(actions.cancelSelection())
      dispatch(actions.exitEditMode())
    },
    onSubmitVehicleJourneys: (next, state) => {
      actions.submitVehicleJourneys(dispatch, state, next)
    },
    validate: (state) =>{
      actions.validate(dispatch, state)
    }
  }
}

const SaveVehicleJourneys = connect(mapStateToProps, mapDispatchToProps)(SaveVehicleJourneysComponent)

export default SaveVehicleJourneys
