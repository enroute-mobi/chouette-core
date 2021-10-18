import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../../actions'
import CompanySelect2 from './select2s/CompanySelect2'
import CustomFieldsInputs from '../../../helpers/CustomFieldsInputs'
import CodesInputs from './CodesInputs'
import _ from 'lodash'

export default class EditVehicleJourney extends Component {
  constructor(props) {
    super(props)
    this.updateValue = this.updateValue.bind(this)
  }

  handleSubmit() {
    if(actions.validateFields(this.refs) == true) {
      var company = undefined
      if(this.props.modal.modalProps.selectedCompany) {
        company = this.props.modal.modalProps.selectedCompany
      } else if (typeof this.props.modal.modalProps.vehicleJourney.company === "object") {
        company = this.props.modal.modalProps.vehicleJourney.company
      }

      this.props.onEditVehicleJourney(_.assign({}, this.refs, {custom_fields: this.props.modal.modalProps.vehicleJourney.custom_fields, referential_codes: this.props.modal.modalProps.vehicleJourney.referential_codes}), company)
      this.props.onModalClose()
      $('#EditVehicleJourneyModal').modal('hide')
    }
  }

  updateValue(attribute, e) {
    this.props.modal.modalProps.vehicleJourney[attribute] = e.target.value
    actions.resetValidation(e.currentTarget)
    this.forceUpdate()
  }

  editMode() {
    return !this.props.modal.modalProps.info && this.props.editMode
  }

  render() {
    if(this.props.status.isFetching == true) {
      return false
    }
    if(this.props.status.fetchSuccess == true) {
      return (
        <li className='st_action'>
          <button
            type='button'
            disabled={(actions.getSelected(this.props.vehicleJourneys).length != 1 || this.props.disabled)}
            data-toggle='modal'
            data-target='#EditVehicleJourneyModal'
            title={ I18n.t('vehicle_journeys.form.hint_info') }
            onClick={() => this.props.onOpenEditModal(actions.getSelected(this.props.vehicleJourneys)[0])}
          >
            <span className='fa fa-info'></span>
          </button>

          <div className={ 'modal fade ' + ((this.props.modal.type == 'duplicate') ? 'in' : '') } id='EditVehicleJourneyModal'>
            <div className='modal-container scrollable-modal'>
              <div className='modal-dialog'>
                <div className='modal-content'>
                  <div className='modal-header'>
                    <h4 className='modal-title'>{I18n.t('vehicle_journeys.form.infos')}</h4>
                    <span type="button" className="close modal-close" data-dismiss="modal">&times;</span>
                  </div>

                  {(this.props.modal.type == 'edit') && (
                    <form>
                      <div className='modal-body'>
                          <div className='row'>
                            <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12'>
                              <div className='form-group'>
                                <label className='control-label'>{I18n.attribute_name('vehicle_journey', 'journey_name')}</label>
                                <input
                                  type='text'
                                  ref='published_journey_name'
                                  className='form-control'
                                  disabled={!this.editMode()}
                                  value={this.props.modal.modalProps.vehicleJourney.published_journey_name}
                                  onChange={(e) => this.updateValue('published_journey_name', e)}
                                  />
                              </div>
                            </div>
                            <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12'>
                              <div className='form-group'>
                                <label className='control-label'>{I18n.attribute_name('vehicle_journey', 'journey_pattern')}</label>
                                <input
                                  type='text'
                                  className='form-control'
                                  value={this.props.modal.modalProps.vehicleJourney.journey_pattern.short_id + ' - ' + (this.props.modal.modalProps.vehicleJourney.journey_pattern.name)}
                                  disabled={true}
                                />
                              </div>
                            </div>
                          </div>

                        <div className='row'>
                          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12'>
                            <div className='form-group'>
                              <label className='control-label'>{I18n.attribute_name('vehicle_journey', 'published_journey_identifier')}</label>
                              <input
                                type='text'
                                ref='published_journey_identifier'
                                className='form-control'
                                disabled={!this.editMode()}
                                value={this.props.modal.modalProps.vehicleJourney.published_journey_identifier}
                                onChange={(e) => this.updateValue('published_journey_identifier', e)}
                              />
                            </div>
                          </div>
                          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12'>
                            <div className='form-group'>
                              <label className='control-label'>{I18n.attribute_name('vehicle_journey', 'company')}</label>
                              <CompanySelect2
                                editModal={this.props.modal.type == "edit"}
                                editMode={this.editMode()}
                                company = {this.props.modal.modalProps.vehicleJourney.company}
                                onSelect2Company = {(e) => this.props.onSelect2Company(e)}
                                onUnselect2Company = {() => this.props.onUnselect2Company()}
                              />
                            </div>
                          </div>
                        </div>

                        <div className='row'>
                          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12'>
                            <div className='form-group'>
                              <label className='control-label'>{I18n.attribute_name('vehicle_journey', 'transport_mode')}</label>
                              <input
                                type='text'
                                className='form-control'
                                value={I18n.enumerize('transport_mode', this.props.modal.modalProps.vehicleJourney.transport_mode)}
                                disabled={true}
                              />
                            </div>
                          </div>
                          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12'>
                            <div className='form-group'>
                              <label className='control-label'>{I18n.attribute_name('vehicle_journey', 'transport_submode')}</label>
                              <input
                                type='text'
                                className='form-control'
                                value={I18n.enumerize('transport_submode', this.props.modal.modalProps.vehicleJourney.transport_submode)}
                                disabled={true}
                              />
                            </div>
                          </div>
                        </div>
                        <div className='form-group'>
                          <label className='control-label'>{I18n.attribute_name('vehicle_journey', 'checksum')}</label>
                            <input
                              type='text'
                              ref='checksum'
                              className='form-control'
                              readOnly={true}
                              value={this.props.modal.modalProps.vehicleJourney.checksum}
                            />
                        </div>
                        <div className='row'>
                          <CustomFieldsInputs
                            values={this.props.modal.modalProps.vehicleJourney.custom_fields}
                            onUpdate={(code, value) => this.custom_fields[code]["value"] = value}
                            disabled={!this.editMode()}
                          />
                        </div>
                        { !(_.isEmpty(window.available_code_spaces)) &&
                          <React.Fragment>
                            <div className='row'>
                              <div className='col-xs-12'>
                                <label className='control-label'>{ I18n.t('vehicle_journeys.form.referential_codes') }</label>
                                <hr className='title-separator'/>
                              </div>
                            </div>
                            <CodesInputs
                              values={this.props.modal.modalProps.vehicleJourney.referential_codes}
                              onAddReferentialCode={this.props.onAddReferentialCode}
                              onDeleteReferentialCode={this.props.onDeleteReferentialCode}
                              onUpdateReferentialCode={this.props.onUpdateReferentialCode}
                              disabled={!this.editMode()}
                            />
                          </React.Fragment>
                        }
                      </div>

                      {
                        this.editMode() &&
                        <div className='modal-footer'>
                          <button
                            className='btn btn-cancel'
                            data-dismiss='modal'
                            type='button'
                            onClick={this.props.onModalClose}
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
        </li>
        )
    } else {
      return false
    }
  }
}

EditVehicleJourney.propTypes = {
  onOpenEditModal: PropTypes.func.isRequired,
  onModalClose: PropTypes.func.isRequired,
  disabled: PropTypes.bool.isRequired
}
