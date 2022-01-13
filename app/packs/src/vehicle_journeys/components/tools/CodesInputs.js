import _ from 'lodash'
import Select2 from 'react-select2-wrapper'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import shortid from 'shortid'


export default class CodesInputs extends Component {
  constructor(props) {
    super(props)
  }

  createNewReferentialCode() {
    return {
      id: null,
      code_space_id: window.available_code_spaces[0].id,
      value: "",
      fallback_id: shortid.generate()
    }
  }

  render() {
    return (
      <div>
        { this.props.values.map((code, index) =>
          <div className="row vertical-align" key={code.id || code.fallback_id}>
            <div className='col-xs-6'>
              <div className='form-group'>
                <select
                  className="form-control"
                  value={code.code_space_id}
                  disabled={this.props.disabled}
                  onChange={(e) => {this.props.onUpdateReferentialCode(index, {code_space_id: +e.target.value})} }
                  >
                  {window.available_code_spaces.map((code_space) =>
                    <option key={code_space.id} value={code_space.id}>{code_space.short_name}</option>
                  )}
                </select>
              </div>
            </div>

            <div className='col-xs-5'>
              <div className='form-group'>
                <input
                  type='text'
                  className='form-control'
                  disabled={this.props.disabled}
                  value={code.value || ""}
                  onChange={(e) => {this.props.onUpdateReferentialCode(index, {value: e.target.value})} }

                  />
              </div>
            </div>
            {!this.props.disabled &&
              <div className='col-xs-1'>
                <div className='form-group'>
                  <button
                    title={I18n.t('actions.delete')}
                    type="button"
                    className=''
                    onClick={() => { this.props.onDeleteReferentialCode(index) }}
                  >
                    <i className='fa fa-trash fa-lg'></i>
                  </button>
                </div>
              </div>
            }
          </div>
        )}
        {!this.props.disabled &&
          <div className="row">
            <button
              className="btn btn-primary pull-right"
              type="button"
              onClick={() => { this.props.onAddReferentialCode(this.createNewReferentialCode()) }}
              >
              { I18n.t('vehicle_journeys.form.add_referential_code') }
            </button>
          </div>
        }
      </div>
    )
  }
}

CodesInputs.propTypes = {
  onUpdateReferentialCode: PropTypes.func.isRequired,
  onDeleteReferentialCode: PropTypes.func.isRequired,
  onAddReferentialCode: PropTypes.func.isRequired,
  values: PropTypes.array.isRequired,
  disabled: PropTypes.bool.isRequired
}
