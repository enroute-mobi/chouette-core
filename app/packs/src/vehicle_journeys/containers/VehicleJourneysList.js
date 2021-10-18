import { toString } from 'lodash'
import { connect } from 'react-redux'
import actions from '../actions'
import VehicleJourneysList from '../components/VehicleJourneysList'

const mapStateToProps = (state) => {
  const { width, height } = state.selection
  const { toggleArrivals, } = state.filters
  const widthMultiplier = toggleArrivals ? 2 : 1
  const dimensionContent = `${toString(width * widthMultiplier)}x${toString(height)}`

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
    onUpdateTime: (value, subIndex, index, timeUnit, isDeparture, isArrivalsToggled, enforceConsistency=false) => {
      dispatch(actions.updateTime(value, subIndex, index, timeUnit, isDeparture, isArrivalsToggled, enforceConsistency))
    },
    onSelectVehicleJourney: (index) => {
      dispatch(actions.selectVehicleJourney(index))
    },
    onOpenInfoModal: (vj) =>{
      dispatch(actions.openInfoModal(vj))
    },
    onKeyDown: (e, selection, toggleArrivals) => {
      const { key, metaKey, ctrlKey } = e
      const { 
        locked,
        copyModal: {
          mode,
          visible
        }
      } = selection
      
      if (visible) {
        if(mode == 'paste' && key == 'Enter') {
          dispatch(actions.pasteContent())
        }
      } else {
        if (!locked) return
        if (!metaKey && !ctrlKey) return

        key == 'c' && dispatch(actions.copyClipboard(toggleArrivals))
        key == 'v' && dispatch(actions.pasteFromClipboard())
      }
    },
    onVisibilityChange: (e)=>{
      dispatch(actions.onVisibilityChange(e))
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(VehicleJourneysList)
