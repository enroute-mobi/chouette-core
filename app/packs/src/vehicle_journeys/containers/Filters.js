import actions from '../actions'
import { connect } from 'react-redux'
import Filters from '../components/Filters'

const mapStateToProps = (state) => {
  return {
    filters: state.filters,
    pagination: state.pagination,
    missions: state.missions,
    vehicleJourneys: state.vehicleJourneys
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
    onSelect2Timetable: selectedItem => {
      dispatch(actions.filterSelect2Timetable(selectedItem))
    },
    onSelect2JourneyPattern: selectedItem => {
      dispatch(actions.filterSelect2JourneyPattern(selectedItem))
    },
    onSelect2VehicleJourney: selectedItem => {
      dispatch(actions.filterSelect2VehicleJourney(selectedItem))
    }
  }
}

const FiltersList = connect(mapStateToProps, mapDispatchToProps)(Filters)

export default FiltersList
