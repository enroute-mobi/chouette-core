import { connect } from 'react-redux'
import actions from '../actions'
import CreateModal from '../components/CreateModal'

const mapStateToProps = (state) => {
  return {
    modal: state.modal,
    journeyPatterns: state.journeyPatterns,
    editMode: state.editMode,
    status: state.status,
    custom_fields: state.custom_fields
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalClose: () =>{
      dispatch(actions.closeModal())
    },
    onAddJourneyPattern: (data) =>{
      dispatch(actions.addJourneyPattern(data))
    },
    onOpenCreateModal: () =>{
      dispatch(actions.openCreateModal())
    },
    onSelectShape: (e) => {
      dispatch(actions.selectShape(e.params.data))
    },
    onUnselectShape: () => {
      dispatch(actions.unselectShape())
    }
  }
}

const AddJourneyPattern = connect(mapStateToProps, mapDispatchToProps)(CreateModal)

export default AddJourneyPattern
