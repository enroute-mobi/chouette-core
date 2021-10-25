import { connect } from 'react-redux'
import actions from '../actions'
import EditModal from '../components/EditModal'
import CreateModal from '../components/CreateModal'

const mapStateToProps = state => ({
  editMode: state.editMode,
  custom_fields: state.custom_fields,
  status: state.status,
  type: state.modal.type,
  ...state.modal.modalProps
})

const mapDispatchToProps = (dispatch) => {
  return {
    onModalClose: () =>{
      dispatch(actions.closeModal())
    },
    saveModal: (index, data) =>{
      dispatch(actions.saveModal(index, data))
    },
    onSelectShape: selectedShape => {
      dispatch(actions.selectShape(selectedShape))
    },
    onUnselectShape: () => {
      dispatch(actions.unselectShape())
    }
  }
}

const ModalContainer = connect(mapStateToProps, mapDispatchToProps)(EditModal)

export default ModalContainer
