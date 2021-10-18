import { connect } from 'react-redux'
import actions from '../actions'
import NavigateComponent from '../components/Navigate'

const mapStateToProps = (state) => {
  return {
    journeyPatterns: state.journeyPatterns,
    status: state.status,
    pagination: state.pagination
  }
}

const Navigate = connect(mapStateToProps)(NavigateComponent)

export default Navigate