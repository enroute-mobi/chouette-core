import { connect } from 'react-redux'
import actions from '../actions'
import EditModal from '../components/EditModal'
import CreateModal from '../components/CreateModal'

const mapStateToProps = (state) => {
  return {
    editMode: state.editMode,
    modal: state.modal,
    journeyPattern: state.journeyPattern,
    custom_fields: state.custom_fields,
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalClose: () =>{
      dispatch(actions.closeModal())
    },
    saveModal: (index, data) =>{
      dispatch(actions.saveModal(index, data))
    },
    onSelectShape: (e) => {
      dispatch(actions.selectShape(e.params.data))
    },
    onUnselectShape: () => {
      dispatch(actions.unselectShape())
    }
  }
}

const ModalContainer = connect(mapStateToProps, mapDispatchToProps)(EditModal, CreateModal)

export default ModalContainer
