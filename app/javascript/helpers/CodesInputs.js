import _ from 'lodash'
import Select2 from 'react-select2-wrapper'
import React, { Component } from 'react'
import PropTypes from 'prop-types'

export default class CodesInputs extends Component {
  constructor(props) {
    super(props)
  }

  render() {
    return (
      <div>
        {_.map(this.props.values, (code) =>
          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12' key={code.id}>
            <div className='form-group'>
              <label className='control-label'>{code.code_space.short_name}</label>
              <input
                type='text'
                ref={'codes.' + code.code_space.short_name}
                className='form-control'
                disabled={this.props.disabled}
                value={code.value || ""}
                onChange={(e) => {this.props.onUpdate(code.code_space.id, e.target.value); this.forceUpdate()} }
                />
            </div>
          </div>
        )}
      </div>
    )
  }
}

CodesInputs.propTypes = {
  onUpdate: PropTypes.func.isRequired,
  values: PropTypes.array.isRequired,
  disabled: PropTypes.bool.isRequired
}
