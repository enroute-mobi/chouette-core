import actions from '../../actions'
import { connect } from 'react-redux'
import NotesEditComponent from '../../components/tools/NotesEditVehicleJourney'

const mapStateToProps = (state, ownProps) => {
  return {
    editMode: state.editMode,
    disabled: ownProps.disabled,
    modal: state.modal,
    vehicleJourneys: state.vehicleJourneys,
    status: state.status
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalClose: () =>{
      dispatch(actions.closeModal())
    },
    onOpenNotesEditModal: (vj) =>{
      dispatch(actions.openNotesEditModal(vj))
    },
    onToggleFootnoteModal: (footnote, isShown) => {
      dispatch(actions.toggleFootnoteModal(footnote, isShown))
    },
    onNotesEditVehicleJourney: (footnotes, line_notices) =>{
      dispatch(actions.editVehicleJourneyNotes(footnotes, line_notices))
    }
  }
}

const NotesEditVehicleJourney = connect(mapStateToProps, mapDispatchToProps)(NotesEditComponent)

export default NotesEditVehicleJourney
