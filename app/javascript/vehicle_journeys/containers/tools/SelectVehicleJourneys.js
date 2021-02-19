import actions from '../../actions'
import { connect } from 'react-redux'
import SelectVJComponent from '../../components/tools/SelectVehicleJourneys'

const mapStateToProps = (state, ownProps) => {
  return {
    disabled: ownProps.disabled,
    selectionMode: state.selection.active
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onToggleTimesSelection: () =>{
      dispatch(actions.toggleTimesSelection())
    },
  }
}

const SelectVehicleJourneys = connect(mapStateToProps, mapDispatchToProps)(SelectVJComponent)

export default SelectVehicleJourneys
