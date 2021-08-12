import React, { Component } from 'react'
import PropTypes from 'prop-types'
import SaveButton from '../../helpers/save_button'
import actions from '../actions'

export default class SaveVehicleJourneys extends SaveButton{
  hasPolicy(){
    return this.props.filters.policy['vehicle_journeys.update'] == true
  }

  formClassName(){
    return 'vehicle_journeys'
  }

  submitForm(){
    this.props.validate(this.props.vehicleJourneys, this.props.dispatch)
  }
}

SaveVehicleJourneys.propTypes = {
  vehicleJourneys: PropTypes.array.isRequired,
  page: PropTypes.number.isRequired,
  status: PropTypes.object.isRequired,
  filters: PropTypes.object.isRequired,
  onEnterEditMode: PropTypes.func.isRequired,
  onExitEditMode: PropTypes.func.isRequired,
  onSubmitVehicleJourneys: PropTypes.func.isRequired
}
