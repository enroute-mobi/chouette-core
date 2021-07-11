import _ from 'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../../actions'
import ConstraintZoneSelect2 from './select2s/ConstraintZoneSelect2'


export default class ConstraintExclusionEditVehicleJourney extends Component {
  constructor(props) {
    super(props)
    this.handleSubmit = this.handleSubmit.bind(this)
    this.constraintZoneUrl = this.constraintZoneUrl.bind(this)
    this.stopAreasConstraintUrl = this.stopAreasConstraintUrl.bind(this)
    this.excluded_constraint_zones = this.excluded_constraint_zones.bind(this)
    this.excluded_stop_area_constraints = this.excluded_stop_area_constraints.bind(this)
    this.constraint_zones = null
    this.stop_area_constraints = null
  }

  handleSubmit() {
    this.props.onConstraintZonesEditVehicleJourney(this.props.modal.modalProps.vehicleJourneys, this.props.modal.modalProps.selectedConstraintZones, this.props.modal.modalProps.selectedStopAreasConstraints)
    this.props.onModalClose()
    $('#ConstraintExclusionEditVehicleJourney').modal('hide')
  }

  constraintZoneUrl(contraint_zone) {
    return window.constraint_zones_routes + "/" + contraint_zone.id
  }

  stopAreasConstraintUrl(contraint) {
    return window.stop_area_constraints_routes + "/" + contraint.id
  }

  excluded_constraint_zones() {
    let out = []
    this.props.modal.modalProps.selectedConstraintZones.map((id, _)=>{
      this.constraint_zones.map((zone, _)=>{
        if(zone.id == id){
          out.push(zone)
        }
      })
    })
    return out
  }

  excluded_stop_area_constraints() {
    let out = []
    this.props.modal.modalProps.selectedStopAreasConstraints.map((id, _)=>{
      this.stop_area_constraints.map((zone, _)=>{
        if(zone.id == id){
          out.push(zone)
        }
      })
    })
    return out
  }

  fetch_constraint_zones() {
    if(this.fetching_constraint_zones){ return }
    this.fetching_constraint_zones = true

    let url = window.constraint_zones_routes + ".json"
    fetch(url, {
      credentials: 'same-origin',
    }).then(response => {
      return response.json()
    }).then((json) => {
      this.constraint_zones = []
      json.map((item, i)=>{
        this.constraint_zones.push(
          _.assign({}, item, {text: item.name})
        )
      })
      this.fetching_constraint_zones = false
      this.forceUpdate()
    })
  }

  fetch_stop_area_constraints() {
    if(this.fetching_stop_area_constraints){ return }
    this.fetching_stop_area_constraints = true

    let url = window.stop_area_constraints_routes + ".json"
    fetch(url, {
      credentials: 'same-origin',
    }).then(response => {
      return response.json()
    }).then((json) => {
      this.stop_area_constraints = []
      json.map((item, i)=>{
        this.stop_area_constraints.push(
          _.assign({}, item, {text: item.name})
        )
      })
      this.fetching_stop_area_constraints = false
      this.forceUpdate()
    })
  }

  render() {
    let fetched = true
    if(this.constraint_zones === null) {
      this.fetch_constraint_zones()
      fetched = false
    }
    if(this.props.stopAreasConstraints && this.stop_area_constraints === null) {
      this.fetch_stop_area_constraints()
      fetched = false
    }
    if(!fetched){
      return false
    }

    if(this.props.status.fetchSuccess == true) {
      return (
        <li className='st_action'>
          <button
            type='button'
            disabled={(actions.getSelected(this.props.vehicleJourneys).length < 1 || this.props.disabled)}
            data-toggle='modal'
            data-target='#ConstraintExclusionEditVehicleJourney'
            onClick={() => this.props.onOpenCalendarsEditModal(actions.getSelected(this.props.vehicleJourneys))}
            title={I18n.t('activerecord.attributes.vehicle_journey.constraint_exclusions')}
          >
            <span className='fa fa-ban fa-strong'></span>
          </button>

          <div className={ 'modal fade ' + ((this.props.modal.type == 'duplicate') ? 'in' : '') } id='ConstraintExclusionEditVehicleJourney'>
            <div className='modal-container'>
              <div className='modal-dialog'>
                <div className='modal-content'>
                  <div className='modal-header'>
                    <h4 className='modal-title'>{I18n.t('activerecord.attributes.vehicle_journey.constraint_exclusions')}</h4>
                    <span type="button" className="close modal-close" data-dismiss="modal">&times;</span>
                  </div>

                  {(this.props.modal.type == 'constraint_exclusions_edit') && (
                    <form>
                      <div className='modal-body'>
                        <div className='row'>
                          <div className='col-lg-12'>
                            <div className='subform'>
                              <div className='nested-head'>
                                <div className='wrapper'>
                                  <div>
                                    <div className='form-group'>
                                      <label className='control-label'>{this.excluded_constraint_zones().length == 0 ? I18n.t('vehicle_journeys.vehicle_journeys_matrix.no_excluded_constraint_zones') : I18n.t('vehicle_journeys.form.excluded_constraint_zones')}</label>
                                    </div>
                                  </div>
                                  <div></div>
                                </div>
                              </div>
                              {this.excluded_constraint_zones().map((contraint_zone, i) =>
                                <div className='nested-fields' key={i}>
                                  <div className='wrapper'>
                                    <div> <a href={this.constraintZoneUrl(contraint_zone)} target="_blank">
                                      {contraint_zone.name}
                                    </a> </div>
                                    {
                                      this.props.editMode &&
                                      <div>
                                        <a
                                          href='#'
                                          title='Supprimer'
                                          className='fa fa-trash remove_fields'
                                          style={{ height: 'auto', lineHeight: 'normal' }}
                                          onClick={(e) => {
                                            e.preventDefault()
                                            this.props.onDeleteConstraintZone(contraint_zone)
                                          }}
                                        ></a>
                                      </div>
                                    }
                                  </div>
                                </div>
                              )}
                              {
                                this.props.editMode &&
                                <div className='nested-fields'>
                                  <div className='wrapper'>
                                    <div>
                                      <ConstraintZoneSelect2
                                        data={this.constraint_zones}
                                        values={this.props.modal.modalProps.constraint_exclusions}
                                        placeholder={I18n.t('vehicle_journeys.vehicle_journeys_matrix.filters.constraint_zone')}
                                        onSelectConstraintZone={this.props.onSelectConstraintZone}
                                      />
                                    </div>
                                  </div>
                                </div>
                              }
                            </div>
                          </div>
                        </div>

                        { this.props.stopAreasConstraints && <div className='row'>
                          <div className='col-lg-12'>
                            <div className='subform'>
                              <div className='nested-head'>
                                <div className='wrapper'>
                                  <div>
                                    <div className='form-group'>
                                      <label className='control-label'>{this.excluded_stop_area_constraints().length == 0 ? I18n.t('vehicle_journeys.vehicle_journeys_matrix.no_excluded_stop_area_constraint') : I18n.t('vehicle_journeys.form.excluded_stop_area_constraints')}</label>
                                    </div>
                                  </div>
                                  <div></div>
                                </div>
                              </div>
                              {this.excluded_stop_area_constraints().map((contraint_zone, i) =>
                                <div className='nested-fields' key={i}>
                                  <div className='wrapper'>
                                    <div> <a href={this.stopAreasConstraintUrl(contraint_zone)} target="_blank">
                                      {contraint_zone.name}
                                    </a> </div>
                                    {
                                      this.props.editMode &&
                                      <div>
                                        <a
                                          href='#'
                                          title='Supprimer'
                                          className='fa fa-trash remove_fields'
                                          style={{ height: 'auto', lineHeight: 'normal' }}
                                          onClick={(e) => {
                                            e.preventDefault()
                                            this.props.onDeleteStopAreasConstraint(contraint_zone)
                                          }}
                                        ></a>
                                      </div>
                                    }
                                  </div>
                                </div>
                              )}
                              {
                                this.props.editMode &&
                                <div className='nested-fields'>
                                  <div className='wrapper'>
                                    <div>
                                      <ConstraintZoneSelect2
                                        data={this.stop_area_constraints}
                                        values={this.props.modal.modalProps.stop_area_constraints}
                                        placeholder={I18n.t('vehicle_journeys.vehicle_journeys_matrix.filters.stop_area_constraint')}
                                        onSelectConstraintZone={this.props.onSelectStopAreasConstraint}
                                      />
                                    </div>
                                  </div>
                                </div>
                              }
                            </div>
                          </div>
                        </div> }
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
                            className='btn btn-default'
                            type='button'
                            onClick={this.handleSubmit}
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

ConstraintExclusionEditVehicleJourney.propTypes = {
  onOpenCalendarsEditModal: PropTypes.func.isRequired,
  onModalClose: PropTypes.func.isRequired,
  disabled: PropTypes.bool.isRequired
}
