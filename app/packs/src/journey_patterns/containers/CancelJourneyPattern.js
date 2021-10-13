import { connect } from 'react-redux'
import CancelJourneyPatternComponent from '../components/CancelJourneyPattern'

const mapStateToProps = (state) => {
  return {
    editMode: state.editMode,
    status: state.status
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onConfirmCancel: () => {
      location.reload()
    },
  }
}

const CancelJourneyPatterns = connect(mapStateToProps, mapDispatchToProps)(CancelJourneyPatternComponent)

export default CancelJourneyPatterns
