import React, { Component } from 'react'
import PropTypes from 'prop-types'

const SwitchInput = ({inputId, inputName, labelText, isChecked, onChange}) => {
  return (
    <div className="form-group has_switch">
      <label className="string optional col-sm-4 col-xs-5 control-label" htmlFor="route_wayback">{labelText}</label>
      <div className="form-group col-sm-8 col-xs-7">
        <div className="checkbox">
          <label className="boolean optional" htmlFor={inputId}>
            <input className="optional" type="checkbox" name={inputName} id={inputId} onChange={onChange} checked={isChecked}/>
            <span className="switch-label" data-checkedvalue={I18n.t('enumerize.route.wayback.outbound')} data-uncheckedvalue={I18n.t('enumerize.route.wayback.inbound')}>
              { I18n.t(`enumerize.route.wayback.${isChecked ? 'outbound' : 'inbound'}`) }
            </span>
          </label>
        </div>
      </div>
    </div>
  )
}

export default SwitchInput

SwitchInput.proptypes = {
  inputId: PropTypes.string.isRequired,
  inputName: PropTypes.string.isRequired,
  labelText: PropTypes.string.isRequired,
  isChecked: PropTypes.bool.isRequired,
  onChange: PropTypes.func.isRequired,
}