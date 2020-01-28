import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../../actions'

export default class VehicleJourneyInfoButton extends Component {
  constructor(props) {
    super(props)
  }


  render() {
    return (
      <div className='info-button'>
        <button
          type='button'
          data-toggle='modal'
          data-target='#EditVehicleJourneyModal'
          title={ I18n.t('vehicle_journeys.form.hint_info') }
          onClick={() => this.props.onOpenEditModal(this.props.vehicleJourney)}
        >
          <span className='fa fa-info'></span>
        </button>
      </div>
    )
  }
}

VehicleJourneyInfoButton.propTypes = {
  onOpenEditModal: PropTypes.func.isRequired,
  vehicleJourney: PropTypes.object.isRequired,
}
