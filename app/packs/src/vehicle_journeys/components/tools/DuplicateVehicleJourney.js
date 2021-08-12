import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../../actions'
import _ from 'lodash'

export default class DuplicateVehicleJourney extends Component {
  constructor(props) {
    super(props)
    this.state = {}
    this.onFormChange = this.onFormChange.bind(this)
    this.handleSubmit = this.handleSubmit.bind(this)
    this.disableValidateButton = this.disableValidateButton.bind(this)
  }

  componentWillReceiveProps() {
    if (actions.getSelected(this.props.vehicleJourneys).length > 0) {
      let hour = parseInt(this.getDefaultValue('hour'))
      let miunte = parseInt(this.getDefaultValue('minute'))
      this.setState((state, props) => {
        return {
          originalDT: {
            hour: hour,
            minute: miunte
          },
          duplicate_time_hh: hour,
          duplicate_time_mm: miunte,
          additional_time: 0,
          duplicate_number: 1
        }
      })
    }
  }

  handleSubmit() {
    if(actions.validateFields(this.refs) == true) {
      let newDeparture = {
        departure_time : {
          hour: this.state.duplicate_time_hh,
          minute: this.state.duplicate_time_mm
        }
      }
      let val = actions.getDuplicateDelta(_.find(actions.getSelected(this.props.vehicleJourneys)[0].vehicle_journey_at_stops, {'dummy': false}), newDeparture)
      this.props.onDuplicateVehicleJourney(this.state.additional_time, this.state.duplicate_number, val)
      this.props.onModalClose()
      $('#DuplicateVehicleJourneyModal').modal('hide')
    }
  }

  onFormChange(e) {
    let {name, value} = e.target
    this.setState((state, props) => {
      return {
        [name]: parseInt(value)
      }
    })
  }

  getDefaultValue(type) {
    let vjas = _.find(actions.getSelected(this.props.vehicleJourneys)[0].vehicle_journey_at_stops, {'dummy': false})
    return vjas.departure_time[type]
  }

  disableValidateButton() {
    /* We disable the button in two cases :
    - if the additional_time_hh or additional_time_mm are above their input max value
    - if if their is no change in the other inputs to avoid making a coping of the selected VJ
    */
    let incorrectDT = isNaN(this.state.duplicate_time_hh) || isNaN(this.state.duplicate_time_mm) || this.state.duplicate_time_hh > 23 || this.state.duplicate_time_mm > 59
    let noInputChanges = this.state.additional_time == 0 && this.state.originalDT.hour == this.state.duplicate_time_hh && this.state.originalDT.minute == this.state.duplicate_time_mm
    return incorrectDT || noInputChanges
  }

  render() {
    if(this.props.status.isFetching == true) {
      return false
    }
    if(this.props.status.fetchSuccess == true) {
      return (
        <li  className='st_action'>
          <button
            type='button'
            disabled={(actions.getSelected(this.props.vehicleJourneys).length == 0 || this.props.disabled)}
            data-toggle='modal'
            data-target='#DuplicateVehicleJourneyModal'
            title={ I18n.t('vehicle_journeys.form.hint_duplicate') }
            onClick={this.props.onOpenDuplicateModal}
          >
            <span className='fa fa-copy'></span>
          </button>

          <div className={ 'modal fade ' + ((this.props.modal.type == 'duplicate') ? 'in' : '') } id='DuplicateVehicleJourneyModal'>
            <div className='modal-container'>
              <div className='modal-dialog'>
                <div className='modal-content'>
                  <div className='modal-header'>
                    <h4 className='modal-title'>
                      {I18n.t('vehicle_journeys.vehicle_journeys_matrix.duplicate', { count: actions.getSelected(this.props.vehicleJourneys).length })}
                    </h4>
                    <span type="button" className="close modal-close" data-dismiss="modal">&times;</span>
                  </div>

                  {(this.props.modal.type == 'duplicate') && (
                    <form className='form-horizontal'>
                      <div className='modal-body'>
                        <div className={'form-group ' + (actions.getSelected(this.props.vehicleJourneys).length > 1 ? 'hidden' : '' )}>
                          <label className='control-label is-required col-sm-8'>{I18n.t('vehicle_journeys.vehicle_journeys_matrix.duplicate.start_time')}</label>
                          <span className="col-sm-4">
                            <span className={'input-group time' + (actions.getSelected(this.props.vehicleJourneys).length > 1 ? ' disabled' : '')}>
                              <input
                                type='number'
                                name='duplicate_time_hh'
                                ref='duplicate_time_hh'
                                min='00'
                                max='23'
                                className='form-control'
                                value={this.state.duplicate_time_hh}
                                onChange={e => this.onFormChange(e)}
                                disabled={actions.getSelected(this.props.vehicleJourneys) && (actions.getSelected(this.props.vehicleJourneys).length > 1 ? 'disabled' : '')}
                                />
                              <span>:</span>
                              <input
                                type='number'
                                name='duplicate_time_mm'
                                ref='duplicate_time_mm'
                                min='00'
                                max='59'
                                className='form-control'
                                value={this.state.duplicate_time_mm}
                                onChange={e => this.onFormChange(e)}
                                disabled={actions.getSelected(this.props.vehicleJourneys) && (actions.getSelected(this.props.vehicleJourneys).length > 1 ? 'disabled' : '')}
                                />
                            </span>
                          </span>
                        </div>

                        <div className='form-group'>
                          <label className='control-label is-required col-sm-8'>{I18n.t('vehicle_journeys.vehicle_journeys_matrix.duplicate.number')}</label>
                          <div className="col-sm-4">
                            <input
                              type='number'
                              style={{'width': 104}}
                              name='duplicate_number'
                              ref='duplicate_number'
                              min='1'
                              max='20'
                              value={this.state.duplicate_number}
                              className='form-control'
                              onChange={e => this.onFormChange(e)}
                              onKeyDown={(e) => actions.resetValidation(e.currentTarget)}
                              required
                              />
                          </div>
                        </div>

                        <div className='form-group'>
                          <label className='control-label is-required col-sm-8'>{I18n.t('vehicle_journeys.vehicle_journeys_matrix.duplicate.delta')}</label>
                          <span className="col-sm-4">
                            <input
                              type='number'
                              style={{'width': 104}}
                              name='additional_time'
                              ref='additional_time'
                              min='-720'
                              max='720'
                              value={this.state.additional_time}
                              className='form-control disabled'
                              onChange={e => this.onFormChange(e)}
                              onKeyDown={(e) => actions.resetValidation(e.currentTarget)}
                              required
                            />
                          </span>
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
                          className={'btn btn-default ' + (this.state.additional_time == 0 && this.state.originalDT.hour == this.state.duplicate_time_hh && this.state.originalDT.minute == this.state.duplicate_time_mm ? 'disabled' : '')}
                          type='button'
                          onClick={this.handleSubmit}
                          disabled={this.disableValidateButton()}
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

DuplicateVehicleJourney.propTypes = {
  onOpenDuplicateModal: PropTypes.func.isRequired,
  onModalClose: PropTypes.func.isRequired,
  disabled: PropTypes.bool.isRequired
}
