import { connect } from 'react-redux'
import assign from 'lodash/assign'
import actions from '../actions'
import PeriodFormComponent from '../components/PeriodForm'



const mapStateToProps = (state) => {
  return {
    modal: state.modal,
    timetable: state.timetable,
    metas: state.metas,
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onOpenAddPeriodForm: () => {
      dispatch(actions.openAddPeriodForm())
    },
    onClosePeriodForm: () => {
      dispatch(actions.closePeriodForm())
    },
    onUpdatePeriodForm: (e, group, selectType, modalProps) => {
      dispatch(actions.updatePeriodForm(e.currentTarget.value, group, selectType))
      let mProps = assign({}, modalProps)
      mProps[group][selectType] = e.currentTarget.value
      let val = window.correctDay([parseInt(mProps[group]['day']), parseInt(mProps[group]['month']), parseInt(mProps[group]['year'])])
      val = (val < 10) ? '0' + String(val) : String(val)
      dispatch(actions.updatePeriodForm(val, group, 'day'))
    },
    onValidatePeriodForm: (modalProps, timeTablePeriods, metas, timetableInDates) => {
      let period_start = actions.formatDate(modalProps.begin)
      let period_end = actions.formatDate(modalProps.end)
      let error = ''
      if (new Date(period_end) <= new Date(period_start)) error = 'La date de départ doit être antérieure à la date de fin'
      if (error == '') error = actions.checkErrorsInPeriods(period_start, period_end, modalProps.index, timeTablePeriods)
      if (error == '') error = actions.checkErrorsInDates(period_start, period_end, timetableInDates)
      dispatch(actions.validatePeriodForm(modalProps, timeTablePeriods, metas, timetableInDates, error))
    }
  }
}

const PeriodForm = connect(mapStateToProps, mapDispatchToProps)(PeriodFormComponent)

export default PeriodForm
