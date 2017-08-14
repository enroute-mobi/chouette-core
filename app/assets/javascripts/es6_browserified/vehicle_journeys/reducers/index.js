var combineReducers = require('redux').combineReducers
var vehicleJourneys = require('./vehicleJourneys')
var pagination = require('./pagination')
var modal = require('./modal')
var status = require('./status')
var filters = require('./filters')
var editMode = require('./editMode')
var stopPointsList = require('./stopPointsList')

const vehicleJourneysApp = combineReducers({
  vehicleJourneys,
  pagination,
  modal,
  status,
  filters,
  editMode,
  stopPointsList
})

module.exports = vehicleJourneysApp
