import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../actions'
import handleRedirect from '../../helpers/redirect'

import { bindAll } from 'lodash'

export default class JourneyPattern extends Component{
  constructor(props){
    super(props)
    this.previousSpId = undefined

    this.basePath = window.location.pathname.split('/journey_patterns_collection')[0]

    bindAll(this, ['updateCosts', 'onCreateShape', 'onEditShape', 'onUnassociateShape', 'onDuplicateJourneyPattern'])
  }

  get journeyPattern() {
    return this.props.value
  }

  get canEditShape() {
    return this.journeyPattern.shape?.has_waypoints
  }

  updateCosts(e) {
    let costs = {
      [e.target.dataset.costsKey]: {
        [e.target.name]: parseFloat(e.target.value)
      }
    }
    this.props.onUpdateJourneyPatternCosts(costs)
  }

  vehicleJourneyURL(jpOid) {
    let routeURL = window.location.pathname.split('/', 7).join('/')
    let vjURL = routeURL + '/vehicle_journeys?jp=' + jpOid

    return (
      <a href={vjURL}>{I18n.t('journey_patterns.journey_pattern.vehicle_journey_at_stops')}</a>
    )
  }

  hasShape() {
    return !!this.journeyPattern.shape?.id
  }

  hasFeature(key) {
    return this.props.status.features[key]
  }

  cityNameChecker(sp, i) {
    return this.props.showHeader((sp.stop_area_object_id || sp.object_id) + "-" + i)
  }

  spNode(sp, headlined){
    return (
      <div
        className={(headlined) ? 'headlined' : ''}
      >
        <div className={'link '}></div>
        <span className='has_radio'>
          <input
            onChange = {(e) => this.props.onCheckboxChange(e)}
            type='checkbox'
            id={sp.position}
            checked={sp.checked}
            disabled={(this.journeyPattern.deletable || this.props.status.policy['journey_patterns.update'] == false || this.props.editMode == false) ? 'disabled' : ''}
            >
          </input>
          <span className='radio-label'></span>
        </span>
      </div>
    )
  }

  getErrors(errors) {
    let err = Object.keys(errors).map((key, index) => {
      return (
        <li key={index} style={{listStyleType: 'disc'}}>
          <strong>{key}</strong> { errors[key] }
        </li>
      )
    })

    return (
      <ul className="alert alert-danger">{err}</ul>
    )
  }

  isDisabled(action) {
    return !this.props.status.policy[`journey_patterns.${action}`]
  }

  totals(onlyCommercial=false){
    let totalTime = 0
    let totalDistance = 0
    let from = null
    this.journeyPattern.stop_points.map((stopPoint, i) =>{
      let usePoint = stopPoint.checked
      if(onlyCommercial && (i == 0 || i == this.journeyPattern.stop_points.length - 1) && stopPoint.kind == "non_commercial"){
        usePoint = false
      }
      if(from && usePoint){
        let [costsKey, costs, time, distance] = this.getTimeAndDistanceBetweenStops(from, stopPoint.id)
        totalTime += time
        totalDistance += distance
      }
      if(usePoint){
        from = stopPoint.id
      }
    })
    return [this.formatTime(totalTime), this.formatDistance(totalDistance)]
  }

  getTimeAndDistanceBetweenStops(from, to){
    let costsKey = from + "-" + to
    let costs = this.getCosts(costsKey)
    let time = costs['time'] || 0
    let distance = costs['distance'] || 0
    return [costsKey, costs, time, distance]
  }

  getCosts(costsKey) {
    let cost = this.journeyPattern.costs[costsKey]

    if (cost) {
      return cost
    }

    if(!this.journeyPattern.id){
      this.props.fetchRouteCosts(costsKey)
    }

    return { distance: 0, time: 0 }
  }

  formatDistance(distance){
    return parseFloat(Math.round(distance * 100) / 100).toFixed(2) + " km"
  }

  formatTime(time){
    if(time < 60){
      return time + " min"
    }
    else{
      let hours = parseInt(time/60)
      let minutes = (time - 60*hours)
      return hours + " h " + (minutes > 0 ? minutes : '')
    }
  }

  onDuplicateJourneyPattern() {
    const { id } = this.journeyPattern

    const url = `${this.basePath}/journey_patterns/${id}/duplicate`

    this.props.onDuplicateJourneyPattern()

    fetch(url, {
      method: 'PUT',
      headers: {
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').attributes.content.value
      }
    })
    .then(handleRedirect(status => {
      sessionStorage.setItem('previousAction', JSON.stringify({
        resource: 'journey_pattern',
        action: 'duplicate',
        status
      }))
    }))
  }

  onCreateShape() {
    const { id } = this.journeyPattern

    const newPathName = `${this.basePath}/journey_patterns/${id}/shapes/new`

    window.location.replace(newPathName)
  }

  onEditShape() {
    const { id } = this.journeyPattern

    const newPathName = `${this.basePath}/journey_patterns/${id}/shapes/edit`

    window.location.replace(newPathName)
  }

  onUnassociateShape() {
    const { id } = this.journeyPattern

    const url = `${this.basePath}/journey_patterns/${id}/unassociate_shape`

    fetch(url, {
      method: 'PUT',
      headers: {
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').attributes.content.value
      }
    })
    .then(handleRedirect(status => {
      sessionStorage.setItem('previousAction', JSON.stringify({
        resource: 'journey_pattern',
        action: 'update',
        status
      }))
    }))
  }

  renderShapeEditorButtons() {
    const { id } = this.journeyPattern

    if (!this.hasFeature('shape_editor_experimental') || !this.props.editMode || !id) return []

    if (!this.hasShape()) {
      return [
        <li key={`create_shape_${id}`}>
          <button
            type='button'
            onClick={this.onCreateShape}
          >
            {I18n.t('journey_patterns.actions.create_shape')}
          </button>
        </li>
      ]
    } else {
      return [
        ...this.canEditShape ?
          [
            <li key={`edit_shape_${id}`}>
              <button
                type='button'
                onClick={this.onEditShape}
              >
                {I18n.t('journey_patterns.actions.edit_shape')}
              </button>
            </li>
          ] :
          [],
        <li key={`unassociate_shape_${id}`}>
          <button
            type="button"
            onClick={this.onUnassociateShape}
          >
            {I18n.t('journey_patterns.actions.unassociate_shape')}
          </button>
        </li>
      ]
    }
  }

  render() {
    this.previousSpId = undefined
    let [totalTime, totalDistance] = this.totals(false)
    let [commercialTotalTime, commercialTotalDistance] = this.totals(true)

    const { deletable, id, object_id, short_id, stop_points } = this.journeyPattern
    return (
      <div className={'t2e-item' + (this.journeyPattern.deletable ? ' disabled' : '') + (object_id ? '' : ' to_record') + (this.journeyPattern.errors ? ' has-error': '') + (this.hasFeature('costs_in_journey_patterns') ? ' with-costs' : '')}>
        <div className='th'>
          <div className='strong mb-xs'>{object_id ? short_id : '-'}</div>
          <div>{this.journeyPattern.registration_number}</div>
          <div>{I18n.t('journey_patterns.show.stop_points_count', {count: actions.getChecked(stop_points).length})}</div>
          {this.hasFeature('costs_in_journey_patterns') &&
            <div className="small row totals">
              <span className="col-md-6"><i className="fas fa-arrows-alt-h"></i>{totalDistance}</span>
              <span className="col-md-6"><i className="fa fa-clock"></i>{totalTime}</span>
            </div>
          }
          {this.hasFeature('costs_in_journey_patterns') &&
            <div className="small row totals commercial">
              <span className="col-md-6"><i className="fas fa-arrows-alt-h"></i>{commercialTotalDistance}</span>
              <span className="col-md-6"><i className="fa fa-clock"></i>{commercialTotalTime}</span>
            </div>
          }
          <div className={deletable ? 'btn-group disabled' : 'btn-group'}>
            <div
              className={deletable ? 'btn dropdown-toggle disabled' : 'btn dropdown-toggle'}
              data-toggle='dropdown'
              >
              <span className='fa fa-cog'></span>
            </div>
            <ul className='dropdown-menu'>
              <li key={`edit_journey_pattern_${id}`}>
                <button
                  type='button'
                  onClick={this.props.onOpenEditModal}
                  data-toggle='modal'
                  data-target='#JourneyPatternModal'
                  >
                  {this.props.editMode ? I18n.t('actions.edit') : I18n.t('actions.show')}
                </button>
              </li>
              {this.props.editMode && !!id && (
                <li key={`duplicate_journey_pattern_${id}`}>
                  <button
                    type='button'
                    onClick={this.onDuplicateJourneyPattern}
                    >
                    {I18n.t('actions.duplicate')}
                  </button>
                </li>
              )}
              { this.renderShapeEditorButtons() }
              <li key={`see_vehicle_journeys_${id}`} className={object_id ? '' : 'disabled'}>
                {object_id ? this.vehicleJourneyURL(object_id) : <a>{I18n.t('journey_patterns.journey_pattern.vehicle_journey_at_stops')}</a> }
              </li>
              <li key={`delete_journey_pattern_${id}`} className={'delete-action' + (this.isDisabled('destroy') || !this.props.editMode ? ' disabled' : '')}>
                <button
                  type='button'
                  className="disabled"
                  disabled={this.isDisabled('destroy') || !this.props.editMode}
                  onClick={(e) => {
                    e.preventDefault()
                    this.props.onDeleteJourneyPattern(this.props.index)}
                  }
                  >
                    <span className='fa fa-trash'></span>{I18n.t('actions.destroy')}
                  </button>
                </li>
              </ul>
            </div>
          </div>

          {stop_points.map((stopPoint, i) =>{
            let costs = null
            let costsKey = null
            let time = null
            let distance = null
            let time_in_words = null
            if(this.previousSpId && stopPoint.checked){
              [costsKey, costs, time, distance] = this.getTimeAndDistanceBetweenStops(this.previousSpId, stopPoint.id)
              time_in_words = this.formatTime(time)
            }
            if(stopPoint.checked){
              this.previousSpId = stopPoint.id
            }
            let headlined = this.cityNameChecker(stopPoint, i)
            return (
              <div key={i} className={(stopPoint.checked ? 'activated' : 'deactivated') + (this.props.editMode ? ' edit-mode' : '')}>
                <div className={'td' + (headlined ? ' with-headline' : '')}>
                  {this.spNode(stopPoint, headlined)}
                </div>
                {this.hasFeature('costs_in_journey_patterns') && costs && <div className='costs' id={'costs-' + id + '-' + costsKey }>
                  {this.props.editMode && <div>
                    <p>
                      <input type="number" value={costs['distance'] || 0} min='0' name="distance" step="0.01" onChange={this.updateCosts} data-costs-key={costsKey}/>
                      <span>km</span>
                    </p>
                    <p>
                      <input type="number" value={costs['time'] || 0} min='0' name="time" onChange={this.updateCosts} data-costs-key={costsKey}/>
                      <span>min</span>
                    </p>
                  </div>}
                  {!this.props.editMode && <div>
                    <p><i className="fas fa-arrows-alt-h"></i>{this.formatDistance(costs['distance'] || 0)}</p>
                    <p><i className="fa fa-clock"></i>{time_in_words}</p>
                  </div>}
                </div>}
              </div>
            )
          })}
        </div>
      )
  }
}

JourneyPattern.propTypes = {
  value: PropTypes.object,
  index: PropTypes.number,
  onCheckboxChange: PropTypes.func.isRequired,
  onOpenEditModal: PropTypes.func.isRequired,
  onDeleteJourneyPattern: PropTypes.func.isRequired,
  showHeader: PropTypes.func.isRequired,
  fetchRouteCosts: PropTypes.func.isRequired,
  onDuplicateJourneyPattern: PropTypes.func.isRequired,
}
