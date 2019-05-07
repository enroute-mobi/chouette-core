import { connect } from 'react-redux'
import AppComponent from '../components/App'

const mapStateToProps = state => ({
  stateChanged: state.pagination.stateChanged
})

const App = connect(mapStateToProps)(AppComponent)

export default App