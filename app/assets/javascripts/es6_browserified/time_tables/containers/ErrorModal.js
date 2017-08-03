var actions = require('../actions')
var connect = require('react-redux').connect
var ErrorModal = require('../components/ErrorModal')

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

module.exports = ErrorModalContainer
