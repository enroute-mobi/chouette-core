import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { flatMap, isEmpty, map, some, uniqBy } from 'lodash'
import autoBind from 'react-autobind'
import VehicleJourney from './VehicleJourney'
import StopAreaHeaderManager from '../../helpers/stop_area_header_manager'
import SelectableContainer from '../containers/SelectableContainer'

export default class VehicleJourneysList extends Component {
  constructor(props){
    super(props)
    this.headerManager = new StopAreaHeaderManager(
      map(this.stopPoints, sp =>  sp.object_id),
      this.stopPoints,
      this.props.filters.features
    )
    autoBind(this)
  }

  // Getters
  get isReturn() {
    return this.props.routeUrl != undefined
  }

  get vehicleJourneysList() {
    const { returnVehicleJourneys, vehicleJourneys } = this.props

    return this.isReturn ? returnVehicleJourneys : vehicleJourneys
  }

  get stopPoints() {
    const { returnStopPointsList, stopPointsList } = this.props

    return this.isReturn ? returnStopPointsList : stopPointsList
  }

  get selectionClasses() {
    if (this.isReturn) return ''

    const out = []

    const { active, locked } = this.props.selection

    active && out.push('selection-mode')
    locked && out.push('selection-locked')

    return out.join(' ')
  }

  get allTimeTables() {
    const tt = flatMap(this.vehicleJourneysList, 'time_tables')
    return uniqBy(tt, 'id')
  }

  // Handlers
  onKeyDown(event) {
    const { selection, onKeyDown, filters } = this.props

    if (this.isReturn) return
    if (!selection.active) return
    if (!this.bubbleKeyEvent(event)) return

    onKeyDown(event, selection, filters.toggleArrivals)
  }

  // Helpers
  hasFeature(key) {
    return this.props.filters.features[key]
  }

  showHeader(object_id) {
    return this.headerManager.showHeader(object_id)
  }

  toggleTimetables(e) {
    let root = $(this.refs['vehicleJourneys'])
    root.find('.table-2entries .detailed-timetables').toggleClass('hidden')
    root.find('.table-2entries .detailed-timetables-bt').toggleClass('active')
    this.componentDidUpdate()
    e.preventDefault()
    false
  }

  timeTableURL(tt) {
    let refURL = window.location.pathname.split('/', 3).join('/')
    let ttURL = refURL + '/time_tables/' + tt.id

    return (
      <a href={ttURL} title='Voir le calendrier'><span className='fa fa-calendar-alt' style={{ color: (tt.color ? tt.color : '#4B4B4B') }}></span>{tt.days || tt.comment}</a>
    )
  }

  extraHeaderLabel(header) {
    if (header["type"] == "custom_field") {
      return this.props.customFields[header["name"]]["name"]
    }
    else {
      return I18n.attribute_name("vehicle_journey", header)
    }
  }

  bubbleKeyEvent(event) {
    const { key, metaKey, ctrlKey } = event
    return (
      key == 'Shift' ||
      (metaKey || ctrlKey) && ['Enter', 'c', 'v'].includes(key)
      )
  }

  // Lifecycle
  componentDidMount() {
    this.props.onLoadFirstPage(this.props.filters, this.props.routeUrl)
  }

  componentDidUpdate(prevProps, prevState) {
    if(this.props.status.isFetching == false){
      $('.table-2entries').each(function() {
        $(this).find('.th').css('height', 'auto')
        var refH = []
        var refCol = []

        $(this).find('.t2e-head').children('div').each(function() {
          var h = this.getBoundingClientRect().height;
          refH.push(h)
        });

        var i = 0
        $(this).find('.t2e-item').children('div').each(function() {
          var h = this.getBoundingClientRect().height;
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
        });

        for(var n = 0; n < refH.length; n++) {
          if(refCol[n] < refH[n]) {
            refCol[n] = refH[n]
          }
        }

        $(this).find('.th').css('height', refCol[0]);

        for(var nth = 1; nth < refH.length; nth++) {
          $(this).find('.td:nth-child('+ (nth + 1) +')').css('height', refCol[nth]);
        }
      })
      document.addEventListener("keydown", this.onKeyDown)
      document.addEventListener("visibilitychange", this.props.onVisibilityChange)
      document.addEventListener("webkitvisibilitychange", this.props.onVisibilityChange)
      document.addEventListener("mozvisibilitychange", this.props.onVisibilityChange)
      document.addEventListener("msvisibilitychange", this.props.onVisibilityChange)
      // document.addEventListener("focusin", this.props.onVisibilityChange)
      window.addEventListener("pageshow", this.props.onVisibilityChange)
      window.addEventListener("focus", this.props.onVisibilityChange)
    }
  }

  render() {
    this.previousBreakpoint = undefined
    let detailed_calendars = this.hasFeature('detailed_calendars') && !this.isReturn && !isEmpty(this.allTimeTables)
    requestAnimationFrame(function(){
      $(document).trigger("table:updated")
    })
    if(this.props.status.isFetching == true) {
      return (
        <div className="isLoading" style={{marginTop: 80, marginBottom: 80}}>
          <div className="loader"></div>
        </div>
      )
    } else {
      return (
        <div
          ref='vehicleJourneys'
          className={`row  ${this.selectionClasses}`.trim()}
          >
          <div className='col-lg-12'>
            {(this.props.status.fetchSuccess == false) && (
              <div className='alert alert-danger mt-sm'>
                <strong>{I18n.tc("error")}</strong>
                {I18n.t("vehicle_journeys.vehicle_journeys_matrix.fetching_error")}
              </div>
            )}

            {some(this.vehicleJourneysList, 'errors') && (
              <div className="alert alert-danger mt-sm">
                <strong>{I18n.tc("error")}</strong>
                {this.vehicleJourneysList.map((vj, index) =>
                  vj.errors && vj.errors.map((err, i) => {
                    return (
                      <ul key={i}>
                        <li>{err}</li>
                      </ul>
                    )
                  })
                )}
              </div>
            )}

            <div className={`table table-2entries mt-sm mb-sm ${isEmpty(this.vehicleJourneysList) ? 'no_result' : ''}`}>
              <div className='t2e-head w20'>
                <div className='th'>
                  <div className='strong mb-xs'>{I18n.attribute_name("vehicle_journey", "id")}</div>
                  <div>{I18n.attribute_name("vehicle_journey", "name")}</div>
                  <div>{I18n.attribute_name("vehicle_journey", "journey_pattern_id")}</div>
                  <div>{I18n.model_name("company")}</div>
                  {
                    this.props.extraHeaders.map((header, i) =>
                      <div key={i}>{this.extraHeaderLabel(header)}</div>
                    )
                  }
                  { this.hasFeature('journey_length_in_vehicle_journeys') &&
                    <div>
                    {I18n.attribute_name("vehicle_journey", "journey_length")}
                    </div>
                  }
                  <div>
                    { detailed_calendars &&
                      <a href='#' onClick={this.toggleTimetables} className='detailed-timetables-bt'>
                        <span className='fa fa-angle-up'></span>
                        {I18n.model_name("time_table", {"plural": true})}
                      </a>
                    }
                    { !detailed_calendars && I18n.model_name("time_table", {"plural": true})}
                  </div>
                  { detailed_calendars &&
                    <div className="detailed-timetables hidden">
                      {this.allTimeTables.map((tt, i)=>
                        <div key={i}>
                          <p>
                            {this.timeTableURL(tt)}
                          </p>
                          <p>{tt.bounding_dates.split(' ').join(' > ')}</p>
                        </div>
                      )}
                    </div>
                  }
                </div>
                {this.stopPoints.map((sp, i) =>{
                  return (
                    <div key={i} className='td'>
                      {this.headerManager.stopPointHeader(sp.object_id)}
                    </div>
                  )
                })}
              </div>
              <SelectableContainer>
                <div className='t2e-item-list'>
                  <div className='scrollable-container'>
                    {this.vehicleJourneysList.map((vj, index) =>
                      <VehicleJourney
                        value={vj}
                        key={index}
                        index={index}
                        editMode={this.isReturn ? false : this.props.editMode}
                        selection={this.props.selection}
                        selectedItems={this.props.selectedItems}
                        filters={this.props.filters}
                        features={this.props.features}
                        onUpdateTime={this.props.onUpdateTime}
                        onSelectVehicleJourney={this.props.onSelectVehicleJourney}
                        onOpenInfoModal={this.props.onOpenInfoModal}
                        vehicleJourneys={this}
                        disabled={this.isReturn}
                        allTimeTables={this.allTimeTables}
                        extraHeaders={this.props.extraHeaders}
                        onSelectCell={this.onSelectCell}
                      />
                    )}
                  </div>
                </div>
              </SelectableContainer>
            </div>
          </div>
        </div>
      )
    }
  }
}

VehicleJourneysList.propTypes = {
  status: PropTypes.object.isRequired,
  filters: PropTypes.object.isRequired,
  extraHeaders: PropTypes.array.isRequired,
  customFields: PropTypes.object.isRequired,
  stopPointsList: PropTypes.array.isRequired,
  onLoadFirstPage: PropTypes.func.isRequired,
  onUpdateTime: PropTypes.func.isRequired,
  onSelectVehicleJourney: PropTypes.func.isRequired
}

VehicleJourneysList.defaultProps = {
  vehicleJourneys: [],
  returnVehicleJourneys: [],
  stopPointsList: [],
  returnStopPointsList: []
}
