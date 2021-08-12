import { connect } from 'react-redux'
import actions from '../actions'
import TimetableComponent from '../components/Timetable'

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
    onAddIncludedDate: (index, dayTypes, date) => {
      dispatch(actions.addIncludedDate(index, dayTypes, date))
    },
    onRemoveIncludedDate: (index, dayTypes, date) => {
      dispatch(actions.removeIncludedDate(index, dayTypes, date))
    },
    onAddExcludedDate: (index, dayTypes, date) => {
      dispatch(actions.addExcludedDate(index, dayTypes, date))
    },
    onRemoveExcludedDate: (index, dayTypes, date) => {
      dispatch(actions.removeExcludedDate(index, dayTypes, date))
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

export default Timetable
