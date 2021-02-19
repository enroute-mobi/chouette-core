import React from 'react'
import VehicleJourneysList from '../containers/VehicleJourneysList'
import Navigate from '../containers/Navigate'
import ToggleArrivals from '../containers/ToggleArrivals'
import Filters from '../containers/Filters'
import CancelVehicleJourneys from '../containers/CancelVehicleJourneys'
import SaveVehicleJourneys from '../containers/SaveVehicleJourneys'
import ConfirmModal from '../containers/ConfirmModal'
import CopyModal from '../containers/CopyModal'
import Tools from '../containers/Tools'
import SelectableContainer from '../containers/SelectableContainer'

export default function App() {
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
      <SelectableContainer>
        <VehicleJourneysList />
      </SelectableContainer>

      <SelectableContainer>
        {window.returnRouteUrl && <VehicleJourneysList routeUrl={window.returnRouteUrl} />}
      </SelectableContainer>

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
