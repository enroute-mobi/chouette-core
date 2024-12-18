import actions from '../../actions'
import { connect } from 'react-redux'
import EditComponent from '../../components/tools/EditVehicleJourney'

const mapStateToProps = (state, ownProps) => {
  return {
    editMode: state.editMode,
    disabled: ownProps.disabled,
    modal: state.modal,
    vehicleJourneys: state.vehicleJourneys,
    status: state.status
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onModalClose: () =>{
      dispatch(actions.closeModal())
    },
    onOpenEditModal: (vj) =>{
      dispatch(actions.openEditModal(vj))
    },
    onEditVehicleJourney: (data, selectedCompany, selectedAccessibilityAssessment) =>{
      dispatch(actions.editVehicleJourney(data, selectedCompany, selectedAccessibilityAssessment))
    },
    onSelect2Company: company => {
      dispatch(actions.select2Company(company))
    },
    onUnselect2Company: () => {
      dispatch(actions.unselect2Company())
    },
    onSelect2AccessibilityAssessment: accessibility_assessment => {
      dispatch(actions.select2AccessibilityAssessment(accessibility_assessment))
    },
    onUnselect2AccessibilityAssessment: () => {
      dispatch(actions.unselect2AccessibilityAssessment())
    },
    onAddReferentialCode: (code) => {
      dispatch(actions.addReferentialCode(code))
    },
    onDeleteReferentialCode: (index) => {
      dispatch(actions.deleteReferentialCode(index))
    },
    onUpdateReferentialCode: (index, attributes) => {
      dispatch(actions.updateReferentialCode(index, attributes))
    },
  }
}

const EditVehicleJourney = connect(mapStateToProps, mapDispatchToProps)(EditComponent)

export default EditVehicleJourney
