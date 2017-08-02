var React = require('react')
var connect = require('react-redux').connect
var actions = require('../actions')
var SaveJourneyPatternComponent = require('../components/SaveJourneyPattern')

const mapStateToProps = (state) => {
  return {
    journeyPatterns: state.journeyPatterns,
    page: state.pagination.page,
    status: state.status
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onEnterEditMode: (e) => {
      e.preventDefault()
      dispatch(actions.enterEditMode())
    },
    onSubmitJourneyPattern: (next, state) => {
      actions.submitJourneyPattern(dispatch, state, next)
      dispatch(actions.exitEditMode())
    }
  }
}

const SaveJourneyPattern = connect(mapStateToProps, mapDispatchToProps)(SaveJourneyPatternComponent)

module.exports = SaveJourneyPattern
