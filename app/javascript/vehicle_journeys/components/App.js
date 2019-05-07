import React, { Component } from 'react'
import VehicleJourneysList from '../containers/VehicleJourneysList'
import Navigate from '../containers/Navigate'
import ToggleArrivals from '../containers/ToggleArrivals'
import Filters from '../containers/Filters'
import CancelVehicleJourneys from '../containers/CancelVehicleJourneys'
import SaveVehicleJourneys from '../containers/SaveVehicleJourneys'
import ConfirmModal from '../containers/ConfirmModal'
import CopyModal from '../containers/CopyModal'
import Tools from '../containers/Tools'

export default class App extends Component {

  componentDidUpdate (prevProps) {
    if (prevProps.stateChanged != this.props.stateChanged && !!this.props.stateChanged) {
      window.onbeforeunload = (e) => {
        (e || window.event).returnValue = 'foobar'
        return 'foobar'
      }
    }
  }

  componentWillUnmount() {
    window.onbeforeunload = undefined
  }

  render () {
    return (
      <div>

        <div className='row'>
          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-6'>
            <ToggleArrivals />
          </div>
          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-6 text-right'>
            <Navigate />
          </div>
        </div>

        <Filters />
        <VehicleJourneysList />
        {window.returnRouteUrl && <VehicleJourneysList routeUrl={window.returnRouteUrl}/>}

        <div className='row'>
          <div className='col-lg-12 text-right'>
            <Navigate />
          </div>
        </div>

        <CancelVehicleJourneys />
        <SaveVehicleJourneys />
        <Tools />

        <ConfirmModal />
        <CopyModal />
      </div>
    )
  }
}
