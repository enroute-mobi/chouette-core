import { connect } from 'react-redux'
import actions from '../actions'
import CreateModal from '../components/CreateModal'

const mapStateToProps = (state) => {

  return {
    editMode: state.editMode,
    status: state.status,
    custom_fields: state.custom_fields,
    status: state.status,
    type: state.modal.type,
    ...state.modal.modalProps
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
    onSelectShape: selectedShape => {
      dispatch(actions.selectShape(selectedShape))
    },
    onUnselectShape: () => {
      dispatch(actions.unselectShape())
    }
  }
}

const AddJourneyPattern = connect(mapStateToProps, mapDispatchToProps)(CreateModal)

export default AddJourneyPattern
