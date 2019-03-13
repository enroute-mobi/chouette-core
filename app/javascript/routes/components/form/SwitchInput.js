import React, { Component } from 'react'
import PropTypes from 'prop-types'

const SwitchInput = ({inputId, inputName, value, labelText, required, onChange}) => {
  return (
    <div className="form-group has_switch">
      <label className="string optional col-sm-4 col-xs-5 control-label" htmlFor="route_wayback">{labelText}</label>
      <div className="form-group col-sm-8 col-xs-7">
        <div className="checkbox">
          <label className="boolean optional" htmlFor={inputId}>
            <input className="optional" data-value={value} type="checkbox" name={inputName} id={inputId} onChange={onChange} />
            <span className="switch-label" data-checkedvalue="Aller" data-uncheckedvalue="Retour">Aller</span>
          </label>
        </div>
      </div>
    </div>
  )
}

export default SwitchInput