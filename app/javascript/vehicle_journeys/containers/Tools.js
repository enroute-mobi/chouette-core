import actions from '../actions'
import { connect } from 'react-redux'
import ToolsComponent from '../components/Tools'

const mapStateToProps = (state) => {
  return {
    vehicleJourneys: state.vehicleJourneys,
    editMode: state.editMode,
    filters: state.filters
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
