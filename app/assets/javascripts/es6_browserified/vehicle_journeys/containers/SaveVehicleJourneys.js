var React = require('react')
var connect = require('react-redux').connect
var actions = require('../actions')
var SaveVehicleJourneysComponent = require('../components/SaveVehicleJourneys')

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
    onSubmitVehicleJourneys: (next, state) => {
      actions.submitVehicleJourneys(dispatch, state, next)
      dispatch(actions.exitEditMode())
    }
  }
}

const SaveVehicleJourneys = connect(mapStateToProps, mapDispatchToProps)(SaveVehicleJourneysComponent)

module.exports = SaveVehicleJourneys
