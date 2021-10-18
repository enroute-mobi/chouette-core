import { connect } from 'react-redux'
import actions from '../actions'
import CancelTimetableComponent from '../components/CancelTimetable'

const mapStateToProps = (state) => {
  return {
    status: state.status
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onConfirmCancel: () => {
      let { pathname, origin } = window.location
      let path = pathname.split('/', 5).join('/')
      window.location = origin + path
    }
  }
}
const CancelTimetable = connect(mapStateToProps, mapDispatchToProps)(CancelTimetableComponent)

export default CancelTimetable
