var React = require('react')
var VehicleJourneysList = require('../containers/VehicleJourneysList')
var Navigate = require('../containers/Navigate')
var ToggleArrivals = require('../containers/ToggleArrivals')
var Filters = require('../containers/Filters')
var SaveVehicleJourneys = require('../containers/SaveVehicleJourneys')
var ConfirmModal = require('../containers/ConfirmModal')
var Tools = require('../containers/Tools')

const App = () => (
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

    <div className='row'>
      <div className='col-lg-12 text-right'>
        <Navigate />
      </div>
    </div>

    <SaveVehicleJourneys />
    <Tools />

    <ConfirmModal />
  </div>
)

module.exports = App
