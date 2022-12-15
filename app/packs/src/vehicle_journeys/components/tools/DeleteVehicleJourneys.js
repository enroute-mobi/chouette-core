import React from 'react'
import PropTypes from 'prop-types'

import actions from '../../actions'

export default function DeleteVehicleJourneys({onDeleteVehicleJourneys, vehicleJourneys, disabled}) {
  return (
    <li className='st_action'>
      <button
        type='button'
        disabled={(actions.getSelected(vehicleJourneys).length == 0 || disabled)}
        onClick={e => {
          e.preventDefault()
          onDeleteVehicleJourneys()
        }}
        title={ I18n.t('actions.delete') }
        className="delete-button"
      >
        <span className='fa fa-trash'></span>
      </button>
    </li>
  )
}

DeleteVehicleJourneys.propTypes = {
  onDeleteVehicleJourneys: PropTypes.func.isRequired,
  vehicleJourneys: PropTypes.array.isRequired,
  disabled: PropTypes.bool.isRequired
}