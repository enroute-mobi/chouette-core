import actions from '../actions'
import { connect } from 'react-redux'
import NavigateComponent from '../components/Navigate'

const mapStateToProps = (state) => {
  return {
    vehicleJourneys: state.vehicleJourneys,
    status: state.status,
    pagination: state.pagination,
    filters: state.filters
  }
}


const Navigate = connect(mapStateToProps)(NavigateComponent)

export default Navigate
