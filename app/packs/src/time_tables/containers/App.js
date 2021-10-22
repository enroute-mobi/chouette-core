import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from'react-redux'
import actions from '../actions'
import Metas from './Metas'
import Timetable from './Timetable'
import Navigate from './Navigate'
import PeriodForm from './PeriodForm'
import PeriodList from './PeriodList'
import CancelTimetable from './CancelTimetable'
import SaveTimetable from './SaveTimetable'
import ConfirmModal from './ConfirmModal'
import ErrorModal from './ErrorModal'
import clone from '../../helpers/clone'

class App extends Component {
  componentDidMount(){
    this.props.onLoadFirstPage()
    document.dispatchEvent(new Event('submitMover'))
  }

  getChildContext() {
    return { I18n }
  }

  render(){
    return(
      <div className='row'>
        <div className="col-lg-8 col-lg-offset-2 col-md-8 col-md-offset-2 col-sm-10 col-sm-offset-1">
          <Metas />
          <Navigate />
          <Timetable />
          <PeriodForm />
          <PeriodList />
          <CancelTimetable />
          <SaveTimetable />
          <ConfirmModal />
          <ErrorModal />
        </div>
      </div>
    )
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    onLoadFirstPage: () =>{
      dispatch(actions.fetchingApi())
      actions.fetchTimeTables(dispatch)
    }
  }
}

App.childContextTypes = {
  I18n: PropTypes.object
}

const timeTableApp = connect(null, mapDispatchToProps)(App)

export default timeTableApp
