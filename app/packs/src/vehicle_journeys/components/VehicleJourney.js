import React, { Component } from 'react'
import PropTypes from 'prop-types'
import autoBind from 'react-autobind'
import { last } from 'lodash'
import actions from '../actions'
import EditVehicleJourney from '../containers/tools/EditVehicleJourney'
import VehicleJourneyInfoButton from '../containers/tools/VehicleJourneyInfoButton'
import VehicleJourneyAtStop from './VehicleJourneyAtStop'
export default class VehicleJourney extends Component {
  constructor(props) {
    super(props)
    this.previousCity = undefined

    autoBind(this)
  }

  // Getters
  get isEditable() {
    return this.props.editMode && !this.props.selection.active
  }

  journey_length() {
    return this.formatDistance(this.props.value.journey_pattern.journey_length)
  }

  cityNameChecker(sp) {
    return this.props.vehicleJourneys.showHeader(sp.stop_point_objectid)
  }

  hasFeature(key) {
    return this.props.filters.features[key]
  }

  timeTableURL(tt) {
    let refURL = window.location.pathname.split('/', 5).join('/')
    let ttURL = refURL + '/time_tables/' + tt.id

    return (
      <a href={ttURL} title={I18n.t('vehicle_journeys.vehicle_journeys_matrix.show_timetable')}><span className='fa fa-calendar-alt' style={{ color: (tt.color ? tt.color : '#4B4B4B')}}></span></a>
    )
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

  extraHeaderValue(header) {
    if(header.type == "custom_field"){
      let field = this.props.value.custom_fields[header["name"]]
      if(field.field_type == "list"){
        return field.options.list_values[field.value]
      }
      else{
        return field.value
      }
    }
    else{
      return this.props.value[header["name"]]
    }
  }

  formatDistance = distance => {
    if (distance < 1000) {
      return distance + " m"
    }
    else {
      return (distance / 1000).toFixed(2) + " km"
    }
  }

  render() {
    this.previousCity = undefined
    let detailed_calendars = this.hasFeature('detailed_calendars') && !this.disabled
    let detailed_calendars_shown = $('.detailed-timetables-bt').hasClass('active')
    let { time_tables } = this.props.value
    const {
      selection: {
        items: selectedItems,
        dimensionContent: selectionDimensionContent
      }
    } = this.props

    const lastSelectedItem = last(selectedItems) || {}


    return (
      <div className={'t2e-item' + (this.props.value.deletable ? ' disabled' : '') + (this.props.value.errors ? ' has-error': '')}>
        <div
          className='th'
          onClick={(e) =>
            !this.props.disabled && ($(e.target).parents("a").length == 0) && this.props.onSelectVehicleJourney(this.props.index)
          }
          >
          <div className='strong mb-xs'>{this.props.value.short_id || '-'}</div>
          <div>
            <a href="#"
              onClick={(e) => {
                if(this.props.disabled){ return }
                e.stopPropagation(true)
                e.preventDefault()
                this.props.onOpenInfoModal(this.props.value)
                $('#EditVehicleJourneyModal').modal('show')
                false
                }
              }
            >
              {this.props.value.published_journey_name && this.props.value.published_journey_name != I18n.t('undefined') ? this.props.value.published_journey_name : '-'}
            </a>
          </div>
          <div>{this.props.value.journey_pattern.short_id || '-'}</div>
          <div>{this.props.value.company ? this.props.value.company.name : '-'}</div>
          {
            this.props.extraHeaders.map((header, i) =>
              <div key={i}>{this.extraHeaderValue(header)}</div>
            )
          }
          { this.hasFeature('journey_length_in_vehicle_journeys') &&
            <div>
              {this.journey_length()}
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
        {this.props.value.vehicle_journey_at_stops.map((vjas, i) => {
          const isInSelection = !!(selectedItems || []).find(({ x, y }) => x == this.props.index && y == i)
          const isSelectionBottomRight = lastSelectedItem.y == i && lastSelectedItem.x == this.props.index

          return (
             <VehicleJourneyAtStop
              key={i}
              x={this.props.index}
              y={i}
              isInSelection={isInSelection}
              vjas={vjas}
              selectionMode={this.props.selection.active}
              isSelectionBottomRight={isSelectionBottomRight}
              selectionContentText={selectionDimensionContent}
              isEditable={this.isEditable}
              isDisabled={this.props.value.deletable || vjas.dummy}
              hasUpdatePermission={this.props.filters.policy['vehicle_journeys.update']}
              onUpdateTime={this.props.onUpdateTime}
              cityNameChecker={this.cityNameChecker}
              toggleArrivals={this.props.filters.toggleArrivals}
            />
          )
        }
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
  extraHeaders: PropTypes.array.isRequired,
  selection: PropTypes.object.isRequired,
}
