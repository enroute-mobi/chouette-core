import React, { Component } from 'react'
import PropTypes from 'prop-types'

const SelectInput = ({inputId, inputName, value, labelText, onChange, options}) => {

  const renderOptions = () => {
    return options.reduce((array, route) => {
      return array.concat (<option key={route.id} value={route.id}>{route.name}</option>)
    }, [<option key='blank' value=''></option>])
  }
  return (
    <div className="form-group opposite_route inbound">
      <label className="col-sm-4 col-xs-5 control-label select optional" htmlFor={inputId}>
        {labelText}
      </label>
      <div className="col-sm-8 col-xs-7">
        <select className="form-control select optional" name={inputName} id={inputId} onChange={onChange} defaultValue={value || ''}>
          { renderOptions() }
        </select>
      </div>
    </div>
  )
}

export default SelectInput

SelectInput.proptypes = {
  inputId: PropTypes.string.isRequired,
  inputName: PropTypes.string.isRequired,
  value: PropTypes.string.isRequired,
  labelText: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  options: PropTypes.array.isRequired,
}