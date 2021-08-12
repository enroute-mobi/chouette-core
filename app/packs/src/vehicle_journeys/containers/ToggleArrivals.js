import actions from '../actions'
import { connect } from 'react-redux'
import ToggleArrivals from '../components/ToggleArrivals'

const mapStateToProps = (state) => {
  return {
    filters: state.filters
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onToggleArrivals: () =>{
      dispatch(actions.toggleArrivals())
    }
  }
}

const ToggleArrivalsList = connect(mapStateToProps, mapDispatchToProps)(ToggleArrivals)

export default ToggleArrivalsList
