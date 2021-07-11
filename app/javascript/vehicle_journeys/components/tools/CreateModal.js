import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../../actions'
import MissionSelect2 from './select2s/MissionSelect2'
import CompanySelect2 from './select2s/CompanySelect2'
import CustomFieldsInputs from '../../../helpers/CustomFieldsInputs'

export default class CreateModal extends Component {
  constructor(props) {
    super(props)
    this.custom_fields = _.assign({}, this.props.custom_fields)
    _.map(this.custom_fields, (cf, k)=>{
      if(cf.options && cf.options.default){
        this.custom_fields[k]["value"] = cf.options.default
      }
    })
  }

  handleSubmit() {
    if(!this.props.modal.modalProps.selectedJPModal){
      let field = $('#NewVehicleJourneyModal').find(".vjCreateSelectJP")
      field.parent().parent().addClass('has-error')
      field.parent().children('.help-block').remove()
      field.parent().append("<span class='small help-block'>" + I18n.t("simple_form.required.text") + "</span>")
      return
    }
    if (actions.validateFields(this.refs, $('.vjCreateSelectJP')[0])) {
      this.props.onAddVehicleJourney(_.assign({}, this.refs, {custom_fields: this.custom_fields}), this.props.modal.modalProps.selectedJPModal, this.props.stopPointsList, this.props.modal.modalProps.vehicleJourney && this.props.modal.modalProps.vehicleJourney.company)
      this.props.onModalClose()
      $('#NewVehicleJourneyModal').modal('hide')
    }
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
            disabled={(this.props.disabled) }
            data-toggle='modal'
            data-target='#NewVehicleJourneyModal'
            title={ I18n.t('vehicle_journeys.form.hint_add_vj') }
            onClick={this.props.onOpenCreateModal}
          >
            <span className='fa fa-plus'></span>
          </button>

          <div className={ 'modal fade ' + ((this.props.modal.type == 'create') ? 'in' : '') } id='NewVehicleJourneyModal'>
            <div className='modal-container'>
              <div className='modal-dialog'>
                <div className='modal-content'>
                  <div className='modal-header'>
                    <h4 className='modal-title'>{I18n.t('vehicle_journeys.actions.new')}</h4>
                    <span type="button" className="close modal-close" data-dismiss="modal">&times;</span>
                  </div>

                  {(this.props.modal.type == 'create') && (
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
                                onKeyDown={(e) => actions.resetValidation(e.currentTarget)}
                                />
                            </div>
                          </div>
                          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12'>
                            <div className='form-group'>
                              <label className='control-label'>{I18n.attribute_name('vehicle_journey', 'company_name')}</label>
                              <CompanySelect2
                                company = {this.props.modal.modalProps.vehicleJourney && this.props.modal.modalProps.vehicleJourney.company || undefined}
                                onSelect2Company = {(e) => this.props.onSelect2Company(e)}
                                onUnselect2Company = {() => this.props.onUnselect2Company()}
                              />
                            </div>
                          </div>
                          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12'>
                            <div className='form-group'>
                              <label className='control-label is-required'>{I18n.attribute_name('vehicle_journey', 'journey_pattern_published_name')}</label>
                              <MissionSelect2
                                selection={this.props.modal.modalProps}
                                onSelect2JourneyPattern={this.props.onSelect2JourneyPattern}
                                values={this.props.missions}
                                isFilter={false}
                              />
                            </div>
                          </div>
                          <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12'>
                            <div className='form-group'>
                              <label className='control-label'>{I18n.attribute_name('vehicle_journey', 'published_journey_identifier')}</label>
                              <input
                                type='text'
                                ref='published_journey_identifier'
                                className='form-control'
                                onKeyDown={(e) => actions.resetValidation(e.currentTarget)}
                                />
                            </div>
                          </div>
                          <CustomFieldsInputs
                            values={this.props.custom_fields}
                            onUpdate={(code, value) => this.custom_fields[code]["value"] = value}
                            disabled={false}
                          />
                          { this.props.modal.modalProps.selectedJPModal && this.props.modal.modalProps.selectedJPModal.full_schedule && <div className='col-lg-6 col-md-6 col-sm-6 col-xs-12'>
                              <div className='form-group'>
                              <label className='control-label'>{I18n.attribute_name('vehicle_journey', 'start_time')}</label>
                                <div className='input-group time'>
                                  <input
                                    type='number'
                                    min='00'
                                    max='23'
                                    ref='start_time.hour'
                                    className='form-control'
                                    onKeyDown={(e) => actions.resetValidation(e.currentTarget)}
                                    />
                                  <input
                                    type='number'
                                    min='00'
                                    max='59'
                                    ref='start_time.minute'
                                    className='form-control'
                                    onKeyDown={(e) => actions.resetValidation(e.currentTarget)}
                                    />
                                  <input
                                    type='hidden'
                                    ref='tz_offset'
                                    value={new Date().getTimezoneOffset()}
                                    />
                                </div>
                              </div>
                            </div>
                          }

                        </div>
                      </div>
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

CreateModal.propTypes = {
  index: PropTypes.number,
  modal: PropTypes.object.isRequired,
  status: PropTypes.object.isRequired,
  stopPointsList: PropTypes.array.isRequired,
  onOpenCreateModal: PropTypes.func.isRequired,
  onModalClose: PropTypes.func.isRequired,
  onAddVehicleJourney: PropTypes.func.isRequired,
  onSelect2JourneyPattern: PropTypes.func.isRequired,
  disabled: PropTypes.bool.isRequired,
  missions: PropTypes.array.isRequired
}
