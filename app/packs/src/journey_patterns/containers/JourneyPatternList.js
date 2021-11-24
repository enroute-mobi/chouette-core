import { connect } from 'react-redux'
import actions from '../actions'
import JourneyPatterns from '../components/JourneyPatterns'

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
    onLoadFirstPage() {
      this.fetchingApi()
      this.fetchJourneyPatterns()
    },
    fetchingApi: () => {
      dispatch(actions.fetchingApi())
    },
    fetchJourneyPatterns: () => {
      return actions.fetchJourneyPatterns(dispatch)
    },
    enterEditMode: () => {
      dispatch(actions.enterEditMode())
    },
    onCheckboxChange: (e, index) =>{
      dispatch(actions.updateCheckboxValue(e, index))
    },
    onOpenEditModal: (index, journeyPattern) =>{
      dispatch(actions.openEditModal(index, journeyPattern))
    },
    onDeleteJourneyPattern: (index) =>{
      dispatch(actions.deleteJourneyPattern(index))
    },
    onUpdateJourneyPatternCosts: (index, costs) =>{
      dispatch(actions.updateJourneyPatternCosts(index, costs))
    },
    fetchRouteCosts: (key, index) => {
      actions.fetchRouteCosts(dispatch, key, index)
    },
    onDuplicateJourneyPattern: () => {
      dispatch(actions.duplicateJourneyPattern())
    }
  }
}

const JourneyPatternList = connect(mapStateToProps, mapDispatchToProps)(JourneyPatterns)

export default JourneyPatternList
