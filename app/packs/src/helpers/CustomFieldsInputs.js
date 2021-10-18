import _ from 'lodash'
import Select2 from 'react-select2-wrapper'
import React, { Component } from 'react'
import PropTypes from 'prop-types'

export default class CustomFieldsInputs extends Component {
  constructor(props) {
    super(props)
  }

  options(cf){
    if(cf.options){
      return cf.options
    }
    return {
      default: ""
    }
  }

  listInput(cf){
    let list_values = this.options(cf).list_values
    let required = !!this.options(cf).required
    let keys = _.orderBy(_.keys(list_values), function(key){ return list_values[key] })
    let data = _.map(keys, (k) => {
      let v = this.options(cf).list_values[k]
      return {id: k, text: (v.length > 0 ? v : '\u00A0')}
    })
    if(!required){
      data.unshift({id: "", text: I18n.t('none')})
    }
    return(
      <Select2
        data={data}
        ref={'custom_fields.' + cf.code}
        className='form-control'
        defaultValue={cf.value !== undefined ? cf.value : this.options(cf).default}
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
        value={cf.value || this.options(cf).default || ""}
        onChange={(e) => {this.props.onUpdate(cf.code, e.target.value); this.forceUpdate()} }
        />
    )
  }

  integerInput(cf){
    return(
      <input
        type='number'
        ref={'custom_fields.' + cf.code}
        className='form-control'
        disabled={this.props.disabled}
        value={cf.value || this.options(cf).default || ""}
        onChange={(e) => {this.props.onUpdate(cf.code, e.target.value); this.forceUpdate()} }
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
