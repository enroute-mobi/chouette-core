import actions from '../actions'
import { connect } from 'react-redux'
import ToolsComponent from '../components/Tools'

const mapStateToProps = (state) => {
  return {
    vehicleJourneys: state.vehicleJourneys,
    editMode: state.editMode,
    selectionMode: state.selection.active,
    filters: state.filters,
    selection: state.selection,
    toggleArrivals: state.filters.toggleArrivals
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onCancelSelection: () => {
      dispatch(actions.cancelSelection())
    },
    onCancelDeletion: () => {
      dispatch(actions.cancelDeletion())
    }
  }
}

const Tools = connect(mapStateToProps, mapDispatchToProps)(ToolsComponent)

export default Tools
