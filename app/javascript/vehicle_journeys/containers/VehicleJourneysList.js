import { toString } from 'lodash'
import { connect } from 'react-redux'
import actions from '../actions'
import VehicleJourneysList from '../components/VehicleJourneysList'

const mapStateToProps = (state) => {
  const { width, height } = state.selection
  const dimensionContent = `${toString(width)}x${toString(height)}`

  return {
    editMode: state.editMode,
    selection: {
      ...state.selection,
      dimensionContent
    },
    vehicleJourneys: state.vehicleJourneys,
    returnVehicleJourneys: state.returnVehicleJourneys,
    status: state.status,
    filters: state.filters,
    stopPointsList: state.stopPointsList,
    returnStopPointsList: state.returnStopPointsList,
    extraHeaders: window.extra_headers,
    customFields: window.custom_fields,
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onLoadFirstPage: (filters, routeUrl) =>{
      dispatch(actions.fetchingApi())
      actions.fetchVehicleJourneys(dispatch, undefined, undefined, filters.queryString, routeUrl)
    },
    onUpdateTime: (e, subIndex, index, timeUnit, isDeparture, isArrivalsToggled, enforceConsistency=false) => {
      dispatch(actions.updateTime(e.target.value, subIndex, index, timeUnit, isDeparture, isArrivalsToggled, enforceConsistency))
    },
    onSelectVehicleJourney: (index) => {
      dispatch(actions.selectVehicleJourney(index))
    },
    onOpenInfoModal: (vj) =>{
      dispatch(actions.openInfoModal(vj))
    },
    // onSelectCell: (x, y, clickDirection, shiftKey)=>{
    //   dispatch(actions.toggleSelection(x, y, clickDirection, shiftKey))
    // },
    // onHoverCell: (x, y, shiftKey)=>{
    //   dispatch(actions.onHoverCell(x, y, shiftKey))
    // },
    onKeyUp: (e)=>{
      dispatch(actions.onKeyUp(e))
    },
    onKeyDown: (e)=>{
      dispatch(actions.onKeyDown(e))
    },
    onVisibilityChange: (e)=>{
      dispatch(actions.onVisibilityChange(e))
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(VehicleJourneysList)
