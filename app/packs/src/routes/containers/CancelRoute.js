import { connect } from 'react-redux'
import CancelRouteComponent from '../components/CancelRoute'

const mapStateToProps = (state) => {
  return {
    editMode: state.status.editMode,
    status: state.status
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onConfirmCancel: () => {
      window.location.assign(window.redirectUrl)
    },
  }
}

const CancelRoute = connect(mapStateToProps, mapDispatchToProps)(CancelRouteComponent)

export default CancelRoute