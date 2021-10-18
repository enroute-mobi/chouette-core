import { connect } from 'react-redux'
import actions from '../actions'
import SaveJourneyPatternComponent from '../components/SaveJourneyPattern'

const mapStateToProps = (state) => {
  return {
    journeyPatterns: state.journeyPatterns,
    editMode: state.editMode,
    page: state.pagination.page,
    status: state.status
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onExitEditMode: () => {
      dispatch(actions.exitEditMode())
    },
    onEnterEditMode: () => {
      dispatch(actions.enterEditMode())
    },
    onSubmitJourneyPattern: (next, state) => {
      actions.submitJourneyPattern(dispatch, state, next)
    }
  }
}

const SaveJourneyPattern = connect(mapStateToProps, mapDispatchToProps)(SaveJourneyPatternComponent)

export default SaveJourneyPattern
