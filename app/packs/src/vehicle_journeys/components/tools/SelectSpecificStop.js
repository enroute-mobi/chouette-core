import _ from 'lodash'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../../actions'
import StopAreaHeaderManager from '../../../helpers/stop_area_header_manager'
import SpecificStopPlaceSelect2 from './select2s/SpecificStopPlaceSelect2'


export default class SelectSpecificStop extends Component {
  constructor(props) {
    super(props)
    this.headerManager = new StopAreaHeaderManager(
      _.map(this.props.stopPointsList, (sp) => {return sp.object_id}),
      this.props.stopPointsList,
      this.props.filters.features
    )
    this.state = { available_specific_stop_places: {} }
    this.selected_specific_stops = {}

    this.addSpecificStopToVJAS = this.addSpecificStopToVJAS.bind(this)
  }

  handleSubmit() {
    if(actions.validateFields(this.refs) == true) {
      // On renvoie les données ici
      this.props.onSelectSpecificStop(this.selected_specific_stops)
      this.props.onModalClose()
      $('#SelectSpecificStopModal').modal('hide')
    }
  }

  addSpecificStopToVJAS(stop_point_id, specific_stop_area_id) {
    this.selected_specific_stops[stop_point_id] = specific_stop_area_id
  }

  componentDidUpdate(prevProps, prevState) {
    if(this.props.status.isFetching == false){
      // Don't forget the .modal pre selector to avoid modifying the DOM outside our modal
      $('.modal .table-2entries').each(function() {
        var refH = []
        var refCol = []

        $(this).find('.t2e-head').children('div').each(function() {
          var h = this.getBoundingClientRect().height
          refH.push(h)
        })

        var i = 0
        $(this).find('.t2e-item').children('div').each(function() {
          var h = this.getBoundingClientRect().height
          if(refCol.length < refH.length){
            refCol.push(h)
          } else {
            if(h > refCol[i]) {
              refCol[i] = h
            }
          }
          if(i == (refH.length - 1)){
            i = 0
          } else {
            i++
          }
        })

        for(var n = 0; n < refH.length; n++) {
          if(refCol[n] < refH[n]) {
            refCol[n] = refH[n]
          }
        }

        $(this).find('.th').css('height', refCol[0])

        for(var nth = 1; nth < refH.length; nth++) {

          // TODO fix this
          // $(this).find('.td:nth-child('+ (nth + 1) +')').css('height', refCol[nth])
          $(this).find('.td:nth-child('+ (nth + 1) +')').css('height', 40)
        }
      })
    }
  }

  fetch_available_specific_stop_places(journey_pattern_id) {
    if(!journey_pattern_id || this.fetching_specific_stops){ return }
    this.fetching_specific_stops = true

    let path = window.available_specific_stop_places_path + ".json"
    let url = path.split(":journey_pattern_id:").join(this.props.modal.modalProps.vehicleJourney.journey_pattern.id)

    fetch(url, {
      credentials: 'same-origin',
    }).then(response => {
      return response.json()
    }).then((json) => {
      /** Adding a text field in each stop area json object is required for displaying it through Select2 **/
      let result = {}
      json.forEach((object1, index1) => {
        result[object1[0]] = object1[1].map((stop_area, index2) => {
          _.assign(stop_area, {
            text: stop_area.name + " - " + stop_area.short_id,
            is_referent: (stop_area.is_referent.toString() || '') /** Prevent "Warning: Received `false` for a non-boolean attribute `is_referent`." **/
          }
        )
          return stop_area
        })
      })
      this.setState({ available_specific_stop_places: result })
      this.fetching_specific_stops = false
    })
  }

  render() {
    let journey_pattern_id = _.get(this.props.modal.modalProps, 'vehicleJourney.journey_pattern.id')
    this.fetch_available_specific_stop_places(journey_pattern_id)

    let id =  _.get(this.props.modal.modalProps, 'vehicleJourney.short_id')

    return (
      <li className='st_action'>
        <button
          type='button'
          disabled={(actions.getSelected(this.props.vehicleJourneys).length != 1 || this.props.disabled)}
          data-toggle='modal'
          data-target='#SelectSpecificStopModal'
          title={ I18n.t('vehicle_journeys.form.hint_specific_stops') }
          onClick={() => this.props.onOpenSelectSpecificStopModal(actions.getSelected(this.props.vehicleJourneys)[0])}
          >
            <span className='fa fa-map-marker'></span>
          </button>

          <div className={ 'modal fade ' + ((this.props.modal.type == 'select_specific_stop') ? 'in' : '') } id='SelectSpecificStopModal'>
            <div className='modal-container scrollable-modal'>
              <div className='modal-dialog'>
                <div className='modal-content'>
                  <div className='modal-header'>
                    <h4 className='modal-title'>{I18n.t('vehicle_journeys.form.specific_stops_title', {id: id})}</h4>
                    <span type="button" className="close modal-close" data-dismiss="modal">&times;</span>
                  </div>

                  {(this.props.modal.type == 'select_specific_stop') && (
                    <form>
                      <div className='modal-body'>
                        <div className='row'>
                          <div className='col-lg-12'>
                            <div className='table table-2entries mt-sm mb-sm'>
                              <div className='t2e-head w50'>
                                <div className='th hidden'>
                                </div>
                                { this.props.modal.modalProps.vehicleJourney.journey_pattern.stop_points.map((sp, i) => {
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
                                { this.props.modal.modalProps.vehicleJourney.vehicle_journey_at_stops.map((vjas, i) => {
                                  if (!vjas.dummy) {
                                    return (
                                      <div key={i} className='td'>
                                        <SpecificStopPlaceSelect2
                                          editMode={this.props.editMode}
                                          data={this.state.available_specific_stop_places[vjas.stop_area_id]}
                                          value={vjas.specific_stop_area_id}
                                          placeholder={I18n.t('vehicle_journeys.vehicle_journeys_matrix.filters.specific_stop_area')}
                                          onSelectSpecificStop={(e) => this.addSpecificStopToVJAS(vjas.stop_point_id ,e)}
                                        />
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

      SelectSpecificStop.propTypes = {
        onOpenSelectSpecificStopModal: PropTypes.func.isRequired,
        onModalClose: PropTypes.func.isRequired,
        disabled: PropTypes.bool.isRequired
      }
