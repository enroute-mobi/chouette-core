import _ from 'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../../actions'
import StopAreaHeaderManager from '../../../helpers/stop_area_header_manager'

const OCCUPANCY_LEVELS = [
  'unknown',
  'empty',
  'many_seats_available',
  'few_seats_available',
  'standing_room_only',
  'crushed_standing_room_only',
  'full',
  'not_accepting_passengers',
  'seats_available',
  'standing_available'
]

export default class SelectOccupancy extends Component {
  constructor(props) {
    super(props)
    this.headerManager = new StopAreaHeaderManager(
      _.map(this.props.stopPointsList, (sp) => { return sp.object_id }),
      this.props.stopPointsList,
      this.props.filters.features
    )
    this.state = {
      default_occupancy_level: '',
      default_occupancy_percentage: '',
      occupancies: {}
    }
    this.selected_occupancies = {}

    this.addOccupancyToVJAS = this.addOccupancyToVJAS.bind(this)
  }

  componentDidUpdate(prevProps, prevState) {
    // Load occupancy data into state when the modal opens
    const vehicleJourney = this.props.modal.modalProps?.vehicleJourney
    if (this.props.modal.type === 'select_occupancy' && prevProps.modal.type !== 'select_occupancy' && vehicleJourney) {
      const occupancies = {}
      if (vehicleJourney.vehicle_journey_at_stops) {
        vehicleJourney.vehicle_journey_at_stops.forEach((vjas) => {
          if (!vjas.dummy) {
            occupancies[vjas.stop_point_id] = {
              occupancy_level: vjas.occupancy_level || '',
              occupancy_percentage: vjas.occupancy_percentage || ''
            }
          }
        })
      }
      this.setState({
        default_occupancy_level: vehicleJourney.occupancy_level || '',
        default_occupancy_percentage: vehicleJourney.occupancy_percentage || '',
        occupancies
      })
    }

    // Adjust table column heights
    if (this.props.status.isFetching == false) {
      // Don't forget the .modal pre selector to avoid modifying the DOM outside our modal
      $('.modal .table-2entries').each(function () {
        var refH = []
        var refCol = []

        $(this).find('.t2e-head').children('div').each(function () {
          var h = this.getBoundingClientRect().height
          refH.push(h)
        })

        var i = 0
        $(this).find('.t2e-item').children('div').each(function () {
          var h = this.getBoundingClientRect().height
          if (refCol.length < refH.length) {
            refCol.push(h)
          } else {
            if (h > refCol[i]) {
              refCol[i] = h
            }
          }
          if (i == (refH.length - 1)) {
            i = 0
          } else {
            i++
          }
        })

        for (var n = 0; n < refH.length; n++) {
          if (refCol[n] < refH[n]) {
            refCol[n] = refH[n]
          }
        }

        $(this).find('.th').css('height', refCol[0])

        for (var nth = 1; nth < refH.length; nth++) {
          $(this).find('.td:nth-child(' + (nth + 1) + ')').css('height', 40)
        }
      })
    }
  }

  handleSubmit() {
    if (actions.validateFields(this.refs) == true) {
      const occupancyData = {
        default_occupancy_level: this.state.default_occupancy_level,
        default_occupancy_percentage: this.state.default_occupancy_percentage,
        occupancies: this.state.occupancies
      }
      this.props.onSelectOccupancy(occupancyData)
      this.props.onModalClose()
      $('#SelectOccupancyModal').modal('hide')
    }
  }

  addOccupancyToVJAS(stop_point_id, field, value) {
    const occupancies = { ...this.state.occupancies }
    if (!occupancies[stop_point_id]) {
      occupancies[stop_point_id] = {
        occupancy_level: '',
        occupancy_percentage: ''
      }
    }
    occupancies[stop_point_id][field] = value
    this.setState({ occupancies })
  }

  render() {
    let id = _.get(this.props.modal.modalProps, 'vehicleJourney.short_id')

    return (
      <li className='st_action'>
        <button
          type='button'
          disabled={(actions.getSelected(this.props.vehicleJourneys).length != 1 || this.props.disabled)}
          data-toggle='modal'
          data-target='#SelectOccupancyModal'
          title={I18n.t('vehicle_journeys.form.hint_occupancy')}
          onClick={() => this.props.onOpenSelectOccupancyModal(actions.getSelected(this.props.vehicleJourneys)[0])}
        >
          <span className='fa fa-users'></span>
        </button>

        <div className={'modal fade ' + ((this.props.modal.type == 'select_occupancy') ? 'in' : '')} id='SelectOccupancyModal'>
          <div className='modal-container scrollable-modal'>
            <div className='modal-dialog'>
              <div className='modal-content'>
                <div className='modal-header'>
                  <h4 className='modal-title'>{I18n.t('vehicle_journeys.form.occupancy_title', { id: id })}</h4>
                  <span type="button" className="close modal-close" data-dismiss="modal">&times;</span>
                </div>

                {(this.props.modal.type == 'select_occupancy') && (
                  <form>
                    <div className='modal-body'>
                      <div className='row'>
                        <div className='col-lg-12'>
                          <div className='form-group'>
                            <label>{I18n.t('vehicle_journeys.form.default_occupancy')}</label>
                            <div className='row'>
                              <div className='col-md-7' style={{ paddingRight: '5px' }}>
                                <select
                                  className='form-control'
                                  value={this.state.default_occupancy_level}
                                  onChange={(e) => this.setState({ default_occupancy_level: e.target.value })}
                                  ref='default_occupancy_level'
                                  disabled={!this.props.editMode}
                                >
                                  <option value=''></option>
                                  {OCCUPANCY_LEVELS.map(level => (
                                    <option key={level} value={level}>{I18n.t(`occupancies.${level}`)}</option>
                                  ))}
                                </select>
                              </div>
                              <div className='col-md-5' style={{ paddingLeft: '5px' }}>
                                <div className='input-group'>
                                  <input
                                    type='number'
                                    className='form-control'
                                    value={this.state.default_occupancy_percentage}
                                    onChange={(e) => this.setState({ default_occupancy_percentage: e.target.value })}
                                    min='0'
                                    max='100'
                                    ref='default_occupancy_percentage'
                                    disabled={!this.props.editMode}
                                  />
                                  <span className='input-group-addon'>%</span>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>

                      <div className='row'>
                        <div className='col-lg-12'>
                          <label>{I18n.t('vehicle_journeys.form.occupancy_per_passing_time')}</label>
                          <div className='table table-2entries mt-sm mb-sm'>
                            <div className='t2e-head w50'>
                              <div className='th hidden'>
                              </div>
                              {this.props.modal.modalProps.vehicleJourney.journey_pattern.stop_points && this.props.modal.modalProps.vehicleJourney.journey_pattern.stop_points.map((sp, i) => {
                                return (
                                  <div key={i} className='td'>
                                    {this.headerManager.stopPointHeader(sp.objectid, false)}
                                  </div>
                                )
                              })}
                            </div>
                            <div className="t2e-item w50">
                              <div className='th hidden'>
                              </div>
                              {this.props.modal.modalProps.vehicleJourney.vehicle_journey_at_stops.map((vjas, i) => {
                                if (!vjas.dummy) {
                                  const occupancy = this.state.occupancies[vjas.stop_point_id] || { occupancy_level: '', occupancy_percentage: '' }
                                  return (
                                    <div key={i} className='td'>
                                      <div className='row'>
                                        <div className='col-md-7' style={{ paddingRight: '5px' }}>
                                          <select
                                            className='form-control input-sm'
                                            value={occupancy.occupancy_level}
                                            onChange={(e) => this.addOccupancyToVJAS(vjas.stop_point_id, 'occupancy_level', e.target.value)}
                                            disabled={!this.props.editMode}
                                          >
                                            <option value=''></option>
                                            {OCCUPANCY_LEVELS.map(level => (
                                              <option key={level} value={level}>{I18n.t(`occupancies.${level}`)}</option>
                                            ))}
                                          </select>
                                        </div>
                                        <div className='col-md-5' style={{ paddingLeft: '5px' }}>
                                          <div className='input-group'>
                                            <input
                                              type='number'
                                              className='form-control input-sm'
                                              value={occupancy.occupancy_percentage}
                                              onChange={(e) => this.addOccupancyToVJAS(vjas.stop_point_id, 'occupancy_percentage', e.target.value)}
                                              min='0'
                                              max='100'
                                              disabled={!this.props.editMode}
                                            />
                                            <span className='input-group-addon'>%</span>
                                          </div>
                                        </div>
                                      </div>
                                    </div>
                                  )
                                }
                              })}
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    {
                      this.props.editMode &&
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
                          className='btn btn-default '
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
  }
}

SelectOccupancy.propTypes = {
  onOpenSelectOccupancyModal: PropTypes.func.isRequired,
  onModalClose: PropTypes.func.isRequired,
  disabled: PropTypes.bool.isRequired
}
