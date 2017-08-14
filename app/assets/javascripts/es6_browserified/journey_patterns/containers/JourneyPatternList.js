var actions = require('../actions')
var connect = require('react-redux').connect
var JourneyPatterns = require('../components/JourneyPatterns')

const mapStateToProps = (state) => {
  return {
    journeyPatterns: state.journeyPatterns,
    status: state.status,
    editMode: state.editMode,
    stopPointsList: state.stopPointsList
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onLoadFirstPage: () =>{
      dispatch(actions.fetchingApi())
      actions.fetchJourneyPatterns(dispatch)
    },
    onCheckboxChange: (e, index) =>{
      dispatch(actions.updateCheckboxValue(e, index))
    },
    onOpenEditModal: (index, journeyPattern) =>{
      dispatch(actions.openEditModal(index, journeyPattern))
    },
    onDeleteJourneyPattern: (index) =>{
      dispatch(actions.deleteJourneyPattern(index))
    }
  }
}

const JourneyPatternList = connect(mapStateToProps, mapDispatchToProps)(JourneyPatterns)

module.exports = JourneyPatternList
