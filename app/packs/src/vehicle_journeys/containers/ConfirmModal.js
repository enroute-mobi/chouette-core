import actions from '../actions'
import { connect } from 'react-redux'
import ConfirmModal from '../components/ConfirmModal'

const mapStateToProps = (state) => {
  return {
    modal: state.modal,
    vehicleJourneys: state.vehicleJourneys
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalAccept: (next, state) =>{
      dispatch(actions.fetchingApi())
      actions.submitVehicleJourneys(dispatch, state, next)
    },
    onModalCancel: (next) =>{
      dispatch(actions.fetchingApi())
      dispatch(next)
    },
    onModalClose: () =>{
      dispatch(actions.closeModal())
    }
  }
}

const ConfirmModalContainer = connect(mapStateToProps, mapDispatchToProps)(ConfirmModal)

export default ConfirmModalContainer
