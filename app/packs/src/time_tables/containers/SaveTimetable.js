import { connect } from 'react-redux'
import actions from '../actions'
import SaveTimetableComponent from '../components/SaveTimetable'

const mapStateToProps = (state) => {
  return {
    timetable: state.timetable,
    metas: state.metas,
    status: state.status
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onShowErrorModal: (errorKey) => {
      dispatch(actions.showErrorModal(errorKey))
    },
    getDispatch: () => {
      return dispatch
    }
  }
}
const SaveTimetable = connect(mapStateToProps, mapDispatchToProps)(SaveTimetableComponent)

export default SaveTimetable
