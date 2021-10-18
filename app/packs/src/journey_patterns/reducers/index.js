import { combineReducers } from 'redux'
import editMode from './editMode'
import status from './status'
import journeyPatterns from './journeyPatterns'
import pagination from './pagination'
import modal from './modal'
import stopPointsList from './stopPointsList'

const journeyPatternsApp = combineReducers({
  editMode,
  status,
  journeyPatterns,
  pagination,
  stopPointsList,
  modal,
  custom_fields: (state = [], action) => state
})

export default journeyPatternsApp
