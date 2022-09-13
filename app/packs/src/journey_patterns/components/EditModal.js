import _ from 'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../actions'
import CustomFieldsInputs from '../../helpers/CustomFieldsInputs'
import ShapeSelector from './ShapeSelector'
import ShapeMap from './ShapeMap'

export default class EditModal extends Component {
  constructor(props) {
    super(props)
    this.updateValue = this.updateValue.bind(this)
  }

  handleSubmit() {
    if(actions.validateFields(this.refs) == true) {
      this.props.saveModal(this.props.index,
        _.assign({}, this.refs, {
          custom_fields: this.custom_fields,
          shape: this.props.journeyPattern.shape ? {id: this.props.journeyPattern.shape.id, name: this.props.journeyPattern.shape.name, uuid: this.props.journeyPattern.shape.uuid } : undefined
        })
      )
      $('#JourneyPatternModal').modal('hide')
    }
  }

  updateValue(attribute, e) {
    actions.resetValidation(e.currentTarget)
    this.props.journeyPattern[attribute] = e.target.value
    this.forceUpdate()
  }

  renderModalTitle() {
    if (this.props.editMode) {
      return (
        <h4 className='modal-title'>
          {I18n.t('journey_patterns.actions.edit')}
          {this.props.type == 'edit' && <em> "{this.props.journeyPattern.name}"</em>}
        </h4>
      )
    } else {
      return <h4 className='modal-title'> {I18n.t('journey_patterns.show.informations')} </h4>
    }
  }

  render() {
    const {
      editMode, index, journeyPattern, type,
      onModalClose, onSelectShape, onUnselectShape
    } = this.props
    if(journeyPattern){
      this.custom_fields = _.assign({}, journeyPattern.custom_fields)
    }
    return (
      <div className={ 'modal fade ' + ((type == 'edit') ? 'in' : '') } id='JourneyPatternModal'>
        <div className='modal-container'>
          <div className='modal-dialog'>
            <div className='modal-content'>
              <div className='modal-header'>
                {this.renderModalTitle()}
                <span type="button" className="close modal-close" data-dismiss="modal">&times;</span>
              </div>
              {(type == 'edit') && (
                <form>
                  <div className='modal-body'>
                    <div className='row'>
                      <div className='col-xs-6'>
                        <div className='form-group'>
                          <label className='control-label is-required'>{I18n.attribute_name('journey_pattern', 'name')}</label>
                          <input
                            type='text'
                            ref='name'
                            className='form-control'
                            disabled={!editMode}
                            id={index}
                            value={journeyPattern.name}
                            onChange={(e) => this.updateValue('name', e)}
                            required
                            />
                        </div>
                      </div>
                    </div>
                    <div className='row'>
                      <div className='col-xs-6'>
                        <div className='form-group'>
                          <label className='control-label'>{I18n.attribute_name('journey_pattern', 'published_name')}</label>
                          <input
                            type='text'
                            ref='published_name'
                            className='form-control'
                            disabled={!editMode}
                            id={index}
                            value={journeyPattern.published_name}
                            onChange={(e) => this.updateValue('published_name', e)}
                            />
                        </div>
                      </div>
                      <div className='col-xs-6'>
                        <div className='form-group'>
                          <label className='control-label'>{I18n.attribute_name('journey_pattern', 'registration_number')}</label>
                          <input
                            type='text'
                            ref='registration_number'
                            className='form-control'
                            disabled={!editMode}
                            id={index}
                            value={journeyPattern.registration_number}
                            onChange={(e) => this.updateValue('registration_number', e)}
                            />
                        </div>
                      </div>
                    </div>
                    <div className='row'>
                      <CustomFieldsInputs
                        values={journeyPattern.custom_fields}
                        onUpdate={(code, value) => this.custom_fields[code]["value"] = value}
                        disabled={!editMode}
                      />
                    </div>
                    <div className='row'>
                      <div className='col-xs-12'>
                        <div className='form-group'>
                          <label className='control-label'>{I18n.attribute_name('journey_pattern', 'shape')}</label>
                          <ShapeSelector
                            shape = {journeyPattern.shape}
                            onSelectShape={onSelectShape}
                            onUnselectShape={onUnselectShape}
                            disabled={!editMode}
                          />
                        </div>
                      </div>
                    </div>
                    {journeyPattern.shape?.id && (
                      <div className='row'>
                        <div className='col-xs-12 shape-map'>
                          <ShapeMap shapeId={journeyPattern.shape.id} />
                        </div>
                      </div>
                    )}
                    <div>
                      <label className='control-label'>{I18n.attribute_name('journey_pattern', 'checksum')}</label>
                        <input
                        type='text'
                        ref='checksum'
                        className='form-control'
                        readOnly={true}
                        value={journeyPattern.checksum}
                        />
                    </div>
                  </div>
                  {
                    editMode &&
                    <div className='modal-footer'>
                      <button
                        className='btn btn-cancel'
                        data-dismiss='modal'
                        type='button'
                        onClick={onModalClose}
                      >
                        {I18n.t('cancel')}
                      </button>
                      <button
                        className='btn btn-default'
                        type='button'
                        onClick={this.handleSubmit.bind(this)}
                      >
                        {I18n.t('actions.submit')}
                      </button>
                    </div>
                  }
                </form>
              )}
            </div>
          </div>
        </div>
      </div>
    )
  }
}

EditModal.propTypes = {
  index: PropTypes.number,
  modal: PropTypes.object,
  onModalClose: PropTypes.func.isRequired,
  saveModal: PropTypes.func.isRequired
}
