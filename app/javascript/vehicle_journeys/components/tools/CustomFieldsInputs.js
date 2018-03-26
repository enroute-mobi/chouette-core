import _ from 'lodash'
import Select2 from 'react-select2-wrapper'
import React, { Component } from 'react'
import PropTypes from 'prop-types'

export default class CustomFieldsInputs extends Component {
  constructor(props) {
    super(props)
  }

  listInput(cf){
    return(
      <Select2
        data={_.map(cf.options.list_values, (v, k) => {
          return {id: k, text: (v.length > 0 ? v : '\u00A0')}
        })}
        ref={'custom_fields.' + cf.code}
        className='form-control'
        defaultValue={cf.value}
        disabled={this.props.disabled}
        options={{
          theme: 'bootstrap',
          width: '100%'
        }}
        onSelect={(e) => this.props.onUpdate(cf.code, e.params.data.id) }
      />
    )
  }

  stringInput(cf){
    return(
      <input
        type='text'
        ref={'custom_fields.' + cf.code}
        className='form-control'
        disabled={this.props.disabled}
        defaultValue={cf.value}
        onChange={(e) => this.props.onUpdate(cf.code, e.target.value) }
        />
    )
  }

  render() {
    return (
      <div>
        {_.map(this.props.values, (cf, code) =>
          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12' key={code}>
            <div className='form-group'>
              <label className='control-label'>{cf.name}</label>
              {this[cf.field_type + "Input"](cf)}
            </div>
          </div>
        )}
      </div>
    )
  }
}

CustomFieldsInputs.propTypes = {
  onUpdate: PropTypes.func.isRequired,
  values: PropTypes.object.isRequired,
  disabled: PropTypes.bool.isRequired
}
