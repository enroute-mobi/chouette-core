import { connect } from 'react-redux'
import actions from '../actions'
import ErrorModal from '../components/ErrorModal'

const mapStateToProps = (state) => {
  return {
    modal: state.modal
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalClose: () =>{
      dispatch(actions.closeModal())
      dispatch(actions.resetModalErrors())
    }
  }
}

const ErrorModalContainer = connect(mapStateToProps, mapDispatchToProps)(ErrorModal)

export default ErrorModalContainer
