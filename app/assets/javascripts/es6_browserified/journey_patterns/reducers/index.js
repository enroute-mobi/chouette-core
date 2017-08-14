var combineReducers = require('redux').combineReducers
var editMode = require('./editMode')
var status = require('./status')
var journeyPatterns = require('./journeyPatterns')
var pagination = require('./pagination')
var modal = require('./modal')
var stopPointsList = require('./stopPointsList')

const journeyPatternsApp = combineReducers({
  editMode,
  status,
  journeyPatterns,
  pagination,
  stopPointsList,
  modal
})

module.exports = journeyPatternsApp
