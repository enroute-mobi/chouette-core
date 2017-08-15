var connect = require('react-redux').connect
var TimetableComponent = require('../components/Timetable')
var actions = require('../actions')

const mapStateToProps = (state) => {
  return {
    metas: state.metas,
    timetable: state.timetable,
    status: state.status
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onDeletePeriod: (index, dayTypes) =>{
      dispatch(actions.deletePeriod(index, dayTypes))
    },
    onExcludeDateFromPeriod: (index, dayTypes, date) => {
      dispatch(actions.excludeDateFromPeriod(index, dayTypes, date))
    },
    onIncludeDateInPeriod: (index, dayTypes, date) => {
      dispatch(actions.includeDateInPeriod(index, dayTypes, date))
    },
    onOpenEditPeriodForm: (period, index) => {
      dispatch(actions.openEditPeriodForm(period, index))
    }
  }
}

const Timetable = connect(mapStateToProps, mapDispatchToProps)(TimetableComponent)

module.exports = Timetable
