import React, { Component } from 'react'
import PropTypes from 'prop-types'
import _ from 'lodash'
import shortid from 'shortid'

export default class CodesList extends Component {
  constructor(props) {
    super(props)
    this.handleAddCode = this.handleAddCode.bind(this)
    this.handleUpdateCodeSpace = this.handleUpdateCodeSpace.bind(this)
    this.handleUpdateCodeValue = this.handleUpdateCodeValue.bind(this)
    this.handleRemoveCode = this.handleRemoveCode.bind(this)
    this.state = {codeValues: this.props.codeValues}
  }

  componentDidUpdate(prevProps) {
    if (prevProps.codeValues !== this.props.codeValues) {
      this.setState({codeValues: this.props.codeValues})
    }
  }

  handleAddCode() {
    this.props.onAddCode({
      id: null,
      code_space_id: window.available_code_spaces[0].id,
      value: "",
      fallback_id: shortid.generate(),
      _destroy: false
    })
  }

  handleUpdateCodeSpace(e, code, index) {
    this.props.onUpdateCode({ code_space_id: e.target.value, value: code.value,  index: index })
    this.setState({codeValues: this.props.codeValues})
  }

  handleUpdateCodeValue(e, code, index) {
    this.props.onUpdateCode({ code_space_id: code.code_space_id, value: e.target.value,  index: index })
    this.setState({codeValues: this.props.codeValues})
  }

  handleRemoveCode(index) {
    this.props.onDeleteCode(index)
    this.setState({codeValues: this.props.codeValues})
  }

  handleDuplicateCodes(codeData) {
    (this.state.codeValues.find(c => c.value === codeData.value && c.code_space_id === codeData.code_space_id && c.id != codeData.id)) &&
    <div className='text-danger p2 small'>
      <i className='glyphicon glyphicon-warning-sign' /> {I18n.t('codes.errors.value_empty')}
    </div>
  }

  handleEmptyCodes(codeData) {
    codeData.value === '' &&
    <div className='text-danger p2 small'>
      <i className='glyphicon glyphicon-warning-sign' /> {I18n.t('codes.errors.value_empty')}
    </div>
  }

  render() {
    return (
      <div className='row'>
        <div className='col-xs-12'>
          <div className='form-group'>
            <label className='control-label'>{ I18n.t('activerecord.attributes.journey_pattern.codes') }</label>
            
            {this.state.codeValues.map((codeData, index) => (
              <div key={codeData.id || codeData.fallback_id} className="row mb-2" style={{ display: codeData._destroy ? 'none' : 'flex' }}>
                <div className="col-sm-4">
                  <select
                    className="form-control"
                    value={codeData.code_space_id}
                    onChange={(e) => {this.handleUpdateCodeSpace(e, codeData, index)}}
                    disabled={!this.props.editMode}
                  >
                    {window.available_code_spaces.map((code_space) =>
                      <option key={code_space.id} value={code_space.id}>
                        {code_space.short_name}
                      </option>
                    )}
                  </select>
                </div>
                <div className="col-sm-4">
                  <input
                    type="text"
                    className="form-control"
                    value={codeData.value}
                    onChange={(e) => {this.handleUpdateCodeValue(e, codeData, index)}}
                    disabled={!this.props.editMode}
                  />
                  {codeData.value === '' &&
                    <div className='text-danger p2 small'>
                      <i className='fas fa-exclamation-triangle' /> {I18n.t('activerecord.errors.models.code.blank')}
                    </div>
                  }
                  {(this.state.codeValues.find(c => c.value === codeData.value && c.code_space_id === codeData.code_space_id && c.id != codeData.id)) &&
                    <div className='text-danger p2 small'>
                      <i className='fas fa-exclamation-triangle' /> {I18n.t('activerecord.errors.models.code.duplicate_values_in_codes')}
                    </div>
                  }
                </div>

                <div className="col-sm-4">
                  <button 
                    type="button"
                    className={`btn pull-right ${!this.props.editMode ? 'btn-secondary' : 'btn-danger'}`} 
                    onClick={() => this.props.editMode && this.handleRemoveCode(index)}
                    disabled={!this.props.editMode}
                  >
                    <i className='fa fa-trash'></i> {I18n.t('actions.delete')}
                  </button>
                </div>
              </div>
            ))}
            
            <div className="row">
              <div className="col-sm-12">
                <button 
                  type="button"
                  className="btn btn-primary"
                  onClick={this.handleAddCode}
                  disabled={!this.props.editMode}
                >
                  <i className='fa fa-plus'></i> {I18n.t('actions.add')}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }
}

CodesList.propTypes = {
  editMode: PropTypes.bool.isRequired,
  codeValues: PropTypes.array,
  onAddCode: PropTypes.func.isRequired,
  onUpdateCode: PropTypes.func.isRequired,
  onDeleteCode: PropTypes.func.isRequired
}
