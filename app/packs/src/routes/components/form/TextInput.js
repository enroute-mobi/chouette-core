import React, { Component } from 'react'
import PropTypes from 'prop-types'

const TextInput = ({inputId, inputName, labelText, value, required, onChange, hasError}) => {
  return (
    <div className={`form-group ${hasError && 'has-error'}` }>
      <label className={`col-sm-4 col-xs-5 control-label string ${required ? 'required' : ''}`} htmlFor={inputId}>
        {labelText} { required ? <abbr title={I18n.t('simple_form.required.text')}>*</abbr> : null}
      </label>
      <div className="col-sm-8 col-xs-7">
        <input className={`form-control string ${required ? 'required' : ''}`} type="text" name={inputName} id={inputId} onChange={onChange} value={value}/>
        { hasError && <span className="help-block small">doit être rempli(e)</span> }
      </div>
  </div>
  )
}

export default TextInput

TextInput.proptypes = {
  inputId: PropTypes.string.isRequired,
  inputName: PropTypes.string.isRequired,
  labelText: PropTypes.string.isRequired,
  value: PropTypes.string.isRequired,
  required: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  hasError: PropTypes.bool.isRequired
}