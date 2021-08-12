import React from 'react'
import PropTypes from 'prop-types'

import actions from '../../actions'

export default function SelectVehicleJourneys({onToggleTimesSelection, disabled, selectionMode}) {
  return (
    <li className='st_action'>
      <button
        type='button'
        disabled={ disabled }
        className={ selectionMode ? 'active' : '' }
        title={ I18n.t('vehicle_journeys.form.hint_copy_paste') }
        onClick={e => {
          e.preventDefault()
          onToggleTimesSelection()
        }}
      >
        <span className='fa fa-object-group'></span>
      </button>
    </li>
  )
}

SelectVehicleJourneys.propTypes = {
  onToggleTimesSelection: PropTypes.func.isRequired,
  disabled: PropTypes.bool.isRequired,
  selectionMode: PropTypes.bool.isRequired
}
