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
      // Créer un journeyPattern vide avec la bonne structure pour le reducer
      const emptyJourneyPatternForReducer = {
        name: { value: '' },
        published_name: { value: '' },
        registration_number: { value: '' },
        booking_arrangement_id: { value: '' },
        code_values: []
      }
      
      // Créer un journeyPattern avec les bonnes valeurs pour EditModal
      const emptyJourneyPatternForModal = {
        name: '',
        published_name: '',
        registration_number: '',
        code_values: []
      }
      
      dispatch(actions.addJourneyPattern(emptyJourneyPatternForReducer))
      // Puis ouvrir la modal d'édition sur ce nouveau journeyPattern (index 0)
      dispatch(actions.openEditModal(0, emptyJourneyPatternForModal))
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
