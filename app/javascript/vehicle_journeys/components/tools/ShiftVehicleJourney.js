import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../../actions'
import _ from 'lodash'

export default class ShiftVehicleJourney extends Component {
  constructor(props) {
    super(props)
    this.state = {
      additional_time: 0
    }
  }

  handleSubmit() {
    if(actions.validateFields(this.refs) == true) {
      this.props.onShiftVehicleJourney(this.state.additional_time)
      this.props.onModalClose()
      $('#ShiftVehicleJourneyModal').modal('hide')
    }
  }

  handleAdditionalTimeChange() {
    this.setState((state, props) => {
      if(this.refs.additional_time.value == "-" || this.refs.additional_time.value == ""){
        return {
          additional_time: this.refs.additional_time.value
        }
      }
      return {
        additional_time: parseInt(this.refs.additional_time.value)
      }
    })
  }

  render() {
    let id =  _.get(actions.getSelected(this.props.vehicleJourneys), ['0', 'short_id'])

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
            data-target='#ShiftVehicleJourneyModal'
            title={ I18n.t('vehicle_journeys.form.hint_shift_vj') }
            onClick={this.props.onOpenShiftModal}
          >
            <span className='sb sb-update-vj'></span>
          </button>

          <div className={ 'modal fade ' + ((this.props.modal.type == 'shift') ? 'in' : '') } id='ShiftVehicleJourneyModal'>
            <div className='modal-container'>
              <div className='modal-dialog'>
                <div className='modal-content'>
                  <div className='modal-header'>
                    <h4 className='modal-title'>{I18n.t('vehicle_journeys.form.slide_title', {id: id})}</h4>
                    <span type="button" className="close modal-close" data-dismiss="modal">&times;</span>
                  </div>

                  {(this.props.modal.type == 'shift') && (
                    <form>
                      <div className='modal-body'>
                        <div className='row'>
                          <div className='col-lg-4 col-lg-offset-4 col-md-4 col-md-offset-4 col-sm-4 col-sm-offset-4 col-xs-12'>
                            <div className='form-group'>
                              <label className='control-label is-required'>{I18n.t('vehicle_journeys.form.slide_delta')}</label>
                              <input
                                type='number'
                                style={{'width': 104}}
                                ref='additional_time'
                                min='-720'
                                max='720'
                                value={this.state.additional_time}
                                className='form-control'
                                onChange={this.handleAdditionalTimeChange.bind(this)}
                                onKeyDown={(e) => actions.resetValidation(e.currentTarget)}
                                required
                              />
                            </div>
                          </div>
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
                          className={'btn btn-default ' + (this.state.additional_time == 0 ? 'disabled' : '')}
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

ShiftVehicleJourney.propTypes = {
  onOpenShiftModal: PropTypes.func.isRequired,
  onModalClose: PropTypes.func.isRequired,
  disabled: PropTypes.bool.isRequired
}
