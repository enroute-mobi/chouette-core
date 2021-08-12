import  { connect } from 'react-redux'
import AppComponent from '../components/App'
import { isActionCreate } from '../reducers/status' 
import {
  fetchResources,
  fetchRoute,
  fetchUserPermissions,
  fetchOppositeRoutes
} from '../actions'

const mapStateToProps = state => ({
  isActionUpdate: !isActionCreate(state.status),
  isFetching: state.status.isFetching
})

const mapDispatchToProps = dispatch => ({
  onLoadFirstPage(mustFetchRoute) {
    fetchResources(dispatch)(mustFetchRoute)()
  }
})

const App = connect (mapStateToProps, mapDispatchToProps)(AppComponent)

export default App