import actions from '../../actions'
import { connect } from 'react-redux'
import VehicleJourneyInfoButtonComponent from '../../components/tools/VehicleJourneyInfoButton'

const mapStateToProps = (state, ownProps) => {
  return {
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onOpenEditModal: (vj) =>{
      dispatch(actions.openInfoModal(vj))
    },
  }
}

const VehicleJourneyInfoButton = connect(mapStateToProps, mapDispatchToProps)(VehicleJourneyInfoButtonComponent)

export default VehicleJourneyInfoButton
