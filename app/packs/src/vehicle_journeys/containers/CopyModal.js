import actions from '../actions'
import { connect } from 'react-redux'
import CopyModal from '../components/CopyModal'

const mapStateToProps = state => {
  const {
    selection: { copyModal }
  } = state

  return {
    ...copyModal
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    closeModal: ()=>{
      dispatch(actions.closeCopyModal())
    },
    toPasteMode: ()=>{
      dispatch(actions.copyModalToPasteMode())
    },
    toCopyMode: () => {
      dispatch(actions.copyModalToCopyMode())
    },
    updatePasteContent: content => {
      dispatch(actions.updateContentToPaste(content))
    },
    pasteContent: ()=>{
      dispatch(actions.pasteContent())
    },
  }
}

const CopyModalContainer = connect(mapStateToProps, mapDispatchToProps)(CopyModal)

export default CopyModalContainer
