import actions from '../../actions'
import { connect } from 'react-redux'
import SelectOccupancyComponent from '../../components/tools/SelectOccupancy'

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
    onOpenSelectOccupancyModal: (data) => {
      dispatch(actions.openSelectOccupancyModal(data))
    },
    onSelectOccupancy: (data) => {
      dispatch(actions.selectOccupancy(data))
    }
  }
}

const SelectOccupancy = connect(mapStateToProps, mapDispatchToProps)(SelectOccupancyComponent)

export default SelectOccupancy
