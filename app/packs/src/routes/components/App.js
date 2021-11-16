import React, { Component } from 'react'
import PropTypes from 'prop-types'
import RouteForm from '../containers/Route'
import AddStopPoint from '../containers/AddStopPoint'
import VisibleStopPoints from'../containers/VisibleStopPoints'
import SaveRoute from'../containers/SaveRoute'
import CancelRoute from'../containers/CancelRoute'

import SubmitMover from '../../helpers/SubmitMover'

export default class App extends Component {
  constructor(props) {
    super(props)
  }
  
  componentDidMount() {
    const { onLoadFirstPage, isActionUpdate } = this.props
    onLoadFirstPage(isActionUpdate).then(() => {
      SubmitMover.init()
    })
  }

  render() {
    if (this.props.isFetching) {
      return (
        <div className="isLoading" style={{marginTop: 80, marginBottom: 80}}>
          <div className="loader"></div>
        </div>
      )
    } else {
      return (
        <div>
          <RouteForm />
          <div className="separator"></div>
          <VisibleStopPoints />
          <AddStopPoint />
          <CancelRoute />
          <SaveRoute />
        </div>
      )
    }
  }
}
