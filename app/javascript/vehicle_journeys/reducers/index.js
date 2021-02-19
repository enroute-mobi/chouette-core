import { combineReducers } from 'redux'
import vehicleJourneys from './vehicleJourneys'
import returnVehicleJourneys from './returnVehicleJourneys'
import pagination from './pagination'
import modal from './modal'
import status from './status'
import filters from './filters'
import editMode from './editMode'
import selection from './selection'
import stopPointsList from './stopPointsList'
import missions from './missions'
import custom_fields from './custom_fields'
// import selectionAndVehicleJourneys from './selectionAndVehicleJourneys'

const vehicleJourneysCombined = combineReducers({
  vehicleJourneys,
  returnVehicleJourneys,
  pagination,
  modal,
  status,
  filters,
  editMode,
  stopPointsList,
  returnStopPointsList: stopPointsList,
  missions,
  custom_fields,
  selection
})

const vehicleJourneysApp = (state = {}, action) => vehicleJourneysCombined(state, action)

export default vehicleJourneysApp
