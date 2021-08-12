import actions from '../actions'
import { connect } from 'react-redux'
import Filters from '../components/Filters'

const mapStateToProps = (state) => {
  return {
    filters: state.filters,
    pagination: state.pagination,
    missions: state.missions,
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onUpdateStartTimeFilter: (e, unit) =>{
      e.preventDefault()
      dispatch(actions.updateStartTimeFilter(e.target.value, unit))
    },
    onUpdateEndTimeFilter: (e, unit) =>{
      e.preventDefault()
      dispatch(actions.updateEndTimeFilter(e.target.value, unit))
    },
    onToggleWithoutSchedule: () =>{
      dispatch(actions.toggleWithoutSchedule())
    },
    onToggleWithoutTimeTable: () =>{
      dispatch(actions.toggleWithoutTimeTable())
    },
    onResetFilters: (e, pagination) =>{
      dispatch(actions.checkConfirmModal(e, actions.resetFilters(dispatch), pagination.stateChanged, dispatch))
    },
    onFilter: (e, pagination) =>{
      dispatch(actions.checkConfirmModal(e, actions.filterQuery(dispatch), pagination.stateChanged, dispatch))
    },
    onSelect2Timetable: (e) => {
      dispatch(actions.filterSelect2Timetable(e.params.data))
    },
    onSelect2JourneyPattern: (e) => {
      dispatch(actions.filterSelect2JourneyPattern(e.params.data))
    },
    onSelect2VehicleJourney: (e) => {
      dispatch(actions.filterSelect2VehicleJourney(e.params.data))
    }
  }
}

const FiltersList = connect(mapStateToProps, mapDispatchToProps)(Filters)

export default FiltersList
