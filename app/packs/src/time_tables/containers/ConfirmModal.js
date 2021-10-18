import { connect } from 'react-redux'
import actions from '../actions'
import ConfirmModal from '../components/ConfirmModal'

const mapStateToProps = (state) => {
  return {
    modal: state.modal,
    timetable: state.timetable,
    metas: state.metas
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalAccept: (next, timetable, metas) =>{
      dispatch(actions.fetchingApi())
      actions.submitTimetable(dispatch, timetable, metas, next)
    },
    onModalCancel: (next) =>{
      dispatch(actions.fetchingApi())
      actions.fetchTimeTables(dispatch)
      dispatch(next)
    },
    onModalClose: () =>{
      dispatch(actions.closeModal())
    }
  }
}

const ConfirmModalContainer = connect(mapStateToProps, mapDispatchToProps)(ConfirmModal)

export default ConfirmModalContainer
