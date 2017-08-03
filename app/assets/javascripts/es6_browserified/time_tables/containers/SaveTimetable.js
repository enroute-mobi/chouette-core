var React = require('react')
var connect = require('react-redux').connect
var actions = require('../actions')
var SaveTimetableComponent = require('../components/SaveTimetable')

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

module.exports = SaveTimetable
