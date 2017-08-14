var connect = require('react-redux').connect
var PeriodFormComponent = require('../components/PeriodForm')
var actions = require('../actions')
var _ = require('lodash')

const mapStateToProps = (state) => {
  return {
    modal: state.modal,
    timetable: state.timetable,
    metas: state.metas,
    currentMonthDaysIn: _.filter(state.timetable.current_month, ['include_date', true])
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
      let mProps = _.assign({}, modalProps)
      mProps[group][selectType] = e.currentTarget.value
      let val = window.correctDay([parseInt(mProps[group]['day']), parseInt(mProps[group]['month']), parseInt(mProps[group]['year'])])
      val = (val < 10) ? '0' + String(val) : String(val)
      dispatch(actions.updatePeriodForm(val, group, 'day'))
    },
    onValidatePeriodForm: (modalProps, timeTablePeriods, metas, currentMonthDaysIn) => {
      dispatch(actions.validatePeriodForm(modalProps, timeTablePeriods, metas, currentMonthDaysIn))
    }
  }
}

const PeriodForm = connect(mapStateToProps, mapDispatchToProps)(PeriodFormComponent)

module.exports = PeriodForm
