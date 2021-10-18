import { connect } from 'react-redux'
import actions from '../actions'
import PeriodListComponent from '../components/PeriodList'

const mapStateToProps = (state) => {
  return {
    metas: state.metas,
    timetable: state.timetable,
    status: state.status,
    pagination: state.pagination
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onDeletePeriod: (index, dayTypes) => {
      dispatch(actions.deletePeriod(index, dayTypes))
    },
    onOpenEditPeriodForm: (period, index) => {
      dispatch(actions.openEditPeriodForm(period, index))
    },
    onZoomOnPeriod: (event, period, pagination, metas, timetable ) => {
      dispatch(actions.checkConfirmModal(event, actions.changePage(dispatch, period.period_start), pagination.stateChanged, dispatch, metas, timetable))
    }
  }
}

const PeriodList = connect(mapStateToProps, mapDispatchToProps)(PeriodListComponent)

export default PeriodList
