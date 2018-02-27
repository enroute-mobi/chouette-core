import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../actions'
import EditVehicleJourney from '../containers/tools/EditVehicleJourney'
import VehicleJourneyInfoButton from '../containers/tools/VehicleJourneyInfoButton'

export default class VehicleJourney extends Component {
  constructor(props) {
    super(props)
    this.previousCity = undefined
  }

  cityNameChecker(sp) {
    return this.props.vehicleJourneys.showHeader(sp.stop_point_objectid)
  }

  hasFeature(key) {
    return this.props.filters.features[key]
  }

  timeTableURL(tt) {
    let refURL = window.location.pathname.split('/', 3).join('/')
    let ttURL = refURL + '/time_tables/' + tt.id

    return (
      <a href={ttURL} title={I18n.t('vehicle_journeys.vehicle_journeys_matrix.show_timetable')}><span className='fa fa-calendar' style={{ color: (tt.color ? tt.color : '#4B4B4B')}}></span></a>
    )
  }

  purchaseWindowURL(tt) {
    let refURL = window.location.pathname.split('/', 3).join('/')
    let ttURL = refURL + '/purchase_windows/' + tt.id

    return (
      <a href={ttURL} title={I18n.t('vehicle_journeys.vehicle_journeys_matrix.show_purchase_window')}><span className='fa fa-calendar' style={{color: (tt.color ? tt.color : '')}}></span></a>
    )
  }

  columnHasDelta() {
    let a = []
    this.props.value.vehicle_journey_at_stops.map((vj, i) => {
      a.push(vj.delta)
    })
    let b = a.reduce((p, c) => p+c, 0)

    if(b > 0) {
      return true
    }
  }

  displayDelta(delta) {
    if(delta > 99){
      return "+"
    }
    return delta
  }


  hasTimeTable(time_tables, tt) {
    let found = false
    time_tables.map((t, index) => {
      if(t.id == tt.id){
        found = true
        return
      }
    })
    return found
  }

  isDisabled(bool1, bool2) {
    return (bool1 || bool2)
  }

  render() {
    this.previousCity = undefined
    let detailed_calendars = this.hasFeature('detailed_calendars') && !this.disabled
    let detailed_calendars_shown = $('.detailed-timetables-bt').hasClass('active')
    let {time_tables, purchase_windows} = this.props.value

    return (
      <div className={'t2e-item' + (this.props.value.deletable ? ' disabled' : '') + (this.props.value.errors ? ' has-error': '')}>
        <div
          className='th'
          onClick={(e) =>
            !this.props.disabled && ($(e.target).parents("a").length == 0) && this.props.onSelectVehicleJourney(this.props.index)
          }
          >
          <div className='strong mb-xs'>{this.props.value.short_id || '-'}</div>
          <div>{this.props.value.published_journey_name && this.props.value.published_journey_name != I18n.t('undefined') ? this.props.value.published_journey_name : '-'}</div>
          <div>{this.props.value.journey_pattern.short_id || '-'}</div>
          <div>{this.props.value.company ? this.props.value.company.name : '-'}</div>
          { this.hasFeature('purchase_windows') &&
            <div>
            {purchase_windows.slice(0,3).map((tt, i)=>
              <span key={i} className='vj_tt'>{this.purchaseWindowURL(tt)}</span>
            )}
            {purchase_windows.length > 3 && <span className='vj_tt'> + {purchase_windows.length - 3}</span>}
            </div>
          }
          <div>
            {time_tables.slice(0,3).map((tt, i)=>
              <span key={i} className='vj_tt'>{this.timeTableURL(tt)}</span>
            )}
            {time_tables.length > 3 && <span className='vj_tt'> + {time_tables.length - 3}</span>}
          </div>
          {!this.props.disabled && <div className={(this.props.value.deletable ? 'disabled ' : '') + 'checkbox'}>
            <input
              id={this.props.index}
              name={this.props.index}
              style={{display: 'none'}}
              onChange={(e) => this.props.onSelectVehicleJourney(this.props.index)}
              type='checkbox'
              disabled={this.props.value.deletable}
              checked={this.props.value.selected}
            ></input>
            <label htmlFor={this.props.index}></label>
          </div>}

          {this.props.disabled && <VehicleJourneyInfoButton vehicleJourney={this.props.value} />}

          { detailed_calendars &&
            <div className={"detailed-timetables" + (detailed_calendars_shown ? "" : " hidden")}>
            {this.props.allTimeTables.map((tt, i) =>
              <div key={i} className={(this.hasTimeTable(time_tables, tt) ? "active" : "inactive")}></div>
            )}
            </div>
          }
        </div>
        {this.props.value.vehicle_journey_at_stops.map((vj, i) =>
          <div key={i} className='td text-center'>
            <div className={'cellwrap' + (this.cityNameChecker(vj) ? ' headlined' : '')}>
              {this.props.filters.toggleArrivals &&
                <div data-headline={I18n.t("vehicle_journeys.form.arrival_at")}>
                  <span className={((this.isDisabled(this.props.value.deletable, vj.dummy) || this.props.filters.policy['vehicle_journeys.update'] == false) ? 'disabled ' : '') + 'input-group time'}>
                    <input
                      type='number'
                      min='00'
                      max='23'
                      className='form-control'
                      disabled={!this.props.editMode || this.isDisabled(this.props.value.deletable, vj.dummy) || this.props.filters.policy['vehicle_journeys.update'] == false}
                      readOnly={!this.props.editMode && !vj.dummy}
                      onChange={(e) => {this.props.onUpdateTime(e, i, this.props.index, 'hour', false, false)}}
                      value={vj.arrival_time['hour']}
                      />
                    <span>:</span>
                    <input
                      type='number'
                      min='00'
                      max='59'
                      className='form-control'
                      disabled={!this.props.editMode || this.isDisabled(this.props.value.deletable, vj.dummy) || this.props.filters.policy['vehicle_journeys.update'] == false}
                      readOnly={!this.props.editMode && !vj.dummy}
                      onChange={(e) => {this.props.onUpdateTime(e, i, this.props.index, 'minute', false, false)}}
                      value={vj.arrival_time['minute']}
                      />
                  </span>
                </div>
                }
                <div className={(this.columnHasDelta() ? '' : 'hidden')}>
                  {(vj.delta != 0) &&
                    <span className='sb sb-chrono sb-lg text-warning' data-textinside={this.displayDelta(vj.delta)}></span>
                  }
                </div>
                <div data-headline={I18n.t("vehicle_journeys.form.departure_at")}>
                  <span className={((this.isDisabled(this.props.value.deletable, vj.dummy) || this.props.filters.policy['vehicle_journeys.update'] == false) ? 'disabled ' : '') + 'input-group time'}>
                    <input
                      type='number'
                      min='00'
                      max='23'
                      className='form-control'
                      disabled={!this.props.editMode || this.isDisabled(this.props.value.deletable, vj.dummy) || this.props.filters.policy['vehicle_journeys.update'] == false}
                      readOnly={!this.props.editMode && !vj.dummy}
                      onChange={(e) => {this.props.onUpdateTime(e, i, this.props.index, 'hour', true, this.props.filters.toggleArrivals)}}
                      value={vj.departure_time['hour']}
                      />
                    <span>:</span>
                    <input
                      type='number'
                      min='00'
                      max='59'
                      className='form-control'
                      disabled={!this.props.editMode || this.isDisabled(this.props.value.deletable, vj.dummy) || this.props.filters.policy['vehicle_journeys.update'] == false}
                      readOnly={!this.props.editMode && !vj.dummy}
                      onChange={(e) => {this.props.onUpdateTime(e, i, this.props.index, "minute", true,  this.props.filters.toggleArrivals)}}
                      value={vj.departure_time['minute']}
                      />
                  </span>
                </div>
                {vj.errors && <div className="errors">
                  {vj.errors}
                </div>}
            </div>
          </div>
        )}
      </div>
    )
  }
}

VehicleJourney.propTypes = {
  value: PropTypes.object.isRequired,
  filters: PropTypes.object.isRequired,
  index: PropTypes.number.isRequired,
  onUpdateTime: PropTypes.func.isRequired,
  onSelectVehicleJourney: PropTypes.func.isRequired,
  vehicleJourneys: PropTypes.object.isRequired,
  allTimeTables: PropTypes.array.isRequired,
}
