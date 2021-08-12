import actions from '../../actions'
import { connect } from 'react-redux'
import SelectSpecificStopComponent from '../../components/tools/SelectSpecificStop'

const mapStateToProps = (state, ownProps) => {
  return {
    editMode: state.editMode,
    modal: state.modal,
    vehicleJourneys: state.vehicleJourneys,
    status: state.status,
    filters: state.filters,
    stopPointsList: state.stopPointsList,
    disabled: ownProps.disabled
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalClose: () => {
      dispatch(actions.closeModal())
    },
    onOpenSelectSpecificStopModal: (data) => {
      dispatch(actions.openSelectSpecificStopModal(data))
    },
    onSelectSpecificStop: (data) => {
      dispatch(actions.selectSpecificStop(data))
    }
  }
}

const SelectSpecificStop = connect(mapStateToProps, mapDispatchToProps)(SelectSpecificStopComponent)

export default SelectSpecificStop
