import { connect } from 'react-redux'
import actions from '../actions'
import CreateModal from '../components/CreateModal'

const mapStateToProps = (state) => {
  return {
    editMode: state.editMode,
    status: state.status,
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
    },
    onAddCode: (index, code) => {
      dispatch(actions.addCode(index, code))
    },
    onUpdateCode: (index, code) => {
      dispatch(actions.updateCode(index, code))
    },
    onDeleteCode: (index, codeIndex) => {
      dispatch(actions.deleteCode(index, codeIndex))
    }
  }
}

const AddJourneyPattern = connect(mapStateToProps, mapDispatchToProps)(CreateModal)

export default AddJourneyPattern
