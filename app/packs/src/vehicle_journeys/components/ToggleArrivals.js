import React from 'react'
import PropTypes from 'prop-types'


export default function ToggleArrivals({filters, onToggleArrivals}) {
  return (
    <div className='has_switch form-group inline'>
      <label htmlFor='toggleArrivals' className='control-label'>{I18n.t('vehicle_journeys.form.show_arrival_time')}</label>
      <div className='form-group'>
        <div className='checkbox'>
          <label>
            <input
              onChange={onToggleArrivals}
              type='checkbox'
              checked={filters.toggleArrivals}
              >
            </input>
            <span className='switch-label'></span>
          </label>
        </div>
      </div>
    </div>
  )
}

ToggleArrivals.propTypes = {
  filters : PropTypes.object.isRequired,
  onToggleArrivals: PropTypes.func.isRequired
}
