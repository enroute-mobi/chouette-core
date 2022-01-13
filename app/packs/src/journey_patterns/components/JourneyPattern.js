import React from 'react'
import PropTypes from 'prop-types'
import { Path } from 'path-parser'

import actions from '../actions'
import xCrsfToken from '../../helpers/xCrsfToken'

const path = new Path('/referentials/:referentialId/lines/:lineId/routes/:routeId')
const params = path.partialTest(location.pathname)
class MutationBuilder {
  constructor(fetchingApi, fetchJourneyPatterns, enterEditMode) {
    this.fetchingApi = fetchingApi
    this.fetchJourneyPatterns = fetchJourneyPatterns
    this.enterEditMode = enterEditMode
  }

   prepare(url, action) {
    return () => fetch(url, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': xCrsfToken
      }
    })
      .then(res => res.json())
      .then(async () => {
        await this.fetchJourneyPatterns()
        await this.enterEditMode()

        this.handleResponse(action, 'notice')
      })
      .catch(() => this.handleResponse(action, 'error'))
  }

  handleResponse = (action, status) => {
    Spruce.stores.flash.add({
      type: 'success',
      text: I18n.t(`flash.actions.${action}.${status}`, {
        resource_name: I18n.t(`activerecord.models.journey_pattern.one`)
      })
    })
  }
}
export default function JourneyPattern({
  editMode,
  enterEditMode,
  fetchingApi,
  fetchRouteCosts,
  fetchJourneyPatterns,
  index,
  onCheckboxChange,
  onDeleteJourneyPattern,
  onOpenEditModal,
  onUpdateJourneyPatternCosts,
  showHeader,
  status,
  value: journeyPattern
}) {
  let previousSpId = undefined
  const basePath = `${path.build(params)}/journey_patterns/${journeyPattern.id}`
  const shape = journeyPattern.shape || {}

  const hasShape = !!shape.id
  const canEditShape = !!shape?.has_waypoints

  const mutationBuilder = new MutationBuilder(fetchingApi, fetchJourneyPatterns, enterEditMode)
  const duplicateJourneyPattern = mutationBuilder.prepare(`${basePath}/duplicate`, 'duplicate')
  const unassociateShape = mutationBuilder.prepare(`${basePath}/unassociate_shape`, 'update')

  const updateCosts = ({ target: { dataset, name, value } }) => {
    const costs = {
      [dataset.costsKey]: {
        [name]: parseFloat(value)
      }
    }
    onUpdateJourneyPatternCosts(costs)
  }

  const vehicleJourneyURL = jpOid => {
    const routeURL = location.pathname.split('/', 7).join('/')
    const vjURL = routeURL + '/vehicle_journeys?jp=' + jpOid

    return <a href={vjURL}>{I18n.t('journey_patterns.journey_pattern.vehicle_journey_at_stops')}</a>
  }

  const hasFeature = key => status.features[key]

  const cityNameChecker = (sp, i) => showHeader((sp.stop_area_object_id || sp.object_id) + "-" + i)

  const spNode = (sp, headlined) => (
    <div
      className={(headlined) ? 'headlined' : ''}
    >
      <div className={'link '}></div>
      <span className='has_radio'>
        <input
          onChange={onCheckboxChange}
          type='checkbox'
          id={sp.position}
          checked={sp.checked}
          disabled={(journeyPattern.deletable || status.policy['journey_patterns.update'] == false || editMode == false) ? 'disabled' : ''}
        >
        </input>
        <span className='radio-label'></span>
      </span>
    </div>
  )

  const isDisabled = action => !status.policy[`journey_patterns.${action}`]

  const totals = (onlyCommercial = false) =>{
    let totalTime = 0
    let totalDistance = 0
    let from = null
    journeyPattern.stop_points.map((stopPoint, i) => {
      let usePoint = stopPoint.checked
      if (onlyCommercial && (i == 0 || i == journeyPattern.stop_points.length - 1) && stopPoint.kind == "non_commercial") {
        usePoint = false
      }
      if (from && usePoint) {
        let [_costsKey, _costs, time, distance] = getTimeAndDistanceBetweenStops(from, stopPoint.id)
        totalTime += time
        totalDistance += distance
      }
      if (usePoint) {
        from = stopPoint.id
      }
    })
    return [formatTime(totalTime), formatDistance(totalDistance)]
  }

  const getTimeAndDistanceBetweenStops = (from, to) => {
    const costsKey = from + "-" + to
    const costs = getCosts(costsKey)
    const time = costs['time'] || 0
    const distance = costs['distance'] || 0
    return [costsKey, costs, time, distance]
  }

  const getCosts = costsKey => {
    const cost = journeyPattern.costs[costsKey]

    if (cost) return cost
  
    if (!journeyPattern.id) { fetchRouteCosts(costsKey) }

    return { distance: 0, time: 0 }
  }

  const formatDistance = distance => parseFloat(Math.round(distance * 100) / 100).toFixed(2) + " km"

  const formatTime = time => {
    if (time < 60) {
      return time + " min"
    }
    else {
      const hours = parseInt(time / 60)
      const minutes = (time - 60 * hours)
      return hours + " h " + (minutes > 0 ? minutes : '')
    }
  }

  const renderShapeEditorButtons = () => {
    const { id } = journeyPattern

    if (!hasFeature('shape_editor_experimental') || !editMode || !id) return []

    if (!hasShape) {
      return [
        <li key={`create_shape_${id}`}>
          <button
            type='button'
            onClick={onCreateShape}
          >
            {I18n.t('journey_patterns.actions.create_shape')}
          </button>
        </li>
      ]
    } else {
      return [
        ...canEditShape ?
          [
            <li key={`edit_shape_${id}`}>
              <button
                type='button'
                onClick={onEditShape}
              >
                {I18n.t('journey_patterns.actions.edit_shape')}
              </button>
            </li>
          ] :
          [],
        <li key={`unassociate_shape_${id}`}>
          <button
            type="button"
            onClick={unassociateShape}
          >
            {I18n.t('journey_patterns.actions.unassociate_shape')}
          </button>
        </li>
      ]
    }
  }

  const onCreateShape = () => { location.replace(`${basePath}/shapes/new`) }

  const onEditShape = () => { location.replace(`${basePath}/shapes/edit`) }

  const [totalTime, totalDistance] = totals(false)
  const [commercialTotalTime, commercialTotalDistance] = totals(true)

  const { deletable, id, object_id, short_id, stop_points } = journeyPattern

  return (
    <div className={'t2e-item' + (journeyPattern.deletable ? ' disabled' : '') + (object_id ? '' : ' to_record') + (journeyPattern.errors ? ' has-error' : '') + (hasFeature('costs_in_journey_patterns') ? ' with-costs' : '')}>
      <div className='th'>
        <div className='strong mb-xs'>{object_id ? short_id : '-'}</div>
        <div>{journeyPattern.registration_number}</div>
        <div>{I18n.t('journey_patterns.show.stop_points_count', { count: actions.getChecked(stop_points).length })}</div>
        {hasFeature('costs_in_journey_patterns') &&
          <div className="small row totals">
            <span className="col-md-6"><i className="fas fa-arrows-alt-h"></i>{totalDistance}</span>
            <span className="col-md-6"><i className="fa fa-clock"></i>{totalTime}</span>
          </div>
        }
        {hasFeature('costs_in_journey_patterns') &&
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
                onClick={onOpenEditModal}
                data-toggle='modal'
                data-target='#JourneyPatternModal'
              >
                {editMode ? I18n.t('actions.edit') : I18n.t('actions.show')}
              </button>
            </li>
            {editMode && !!id && (
              <li key={`duplicate_journey_pattern_${id}`}>
                <button
                  type='button'
                  onClick={() => duplicateJourneyPattern()}
                >
                  {I18n.t('actions.duplicate')}
                </button>
              </li>
            )}
            {renderShapeEditorButtons()}
            <li key={`see_vehicle_journeys_${id}`} className={object_id ? '' : 'disabled'}>
              {object_id ? vehicleJourneyURL(object_id) : <a>{I18n.t('journey_patterns.journey_pattern.vehicle_journey_at_stops')}</a>}
            </li>
            <li key={`delete_journey_pattern_${id}`} className={'delete-action' + (isDisabled('destroy') || !editMode ? ' disabled' : '')}>
              <button
                type='button'
                className="disabled"
                disabled={isDisabled('destroy') || !editMode}
                onClick={(e) => {
                  e.preventDefault()
                  onDeleteJourneyPattern(index)
                }
                }
              >
                <span className='fa fa-trash'></span>{I18n.t('actions.destroy')}
              </button>
            </li>
          </ul>
        </div>
      </div>

      {stop_points.map((stopPoint, i) => {
        let costs = null
        let costsKey = null
        let time = null
        let distance = null
        let time_in_words = null
        if (previousSpId && stopPoint.checked) {
          [costsKey, costs, time, distance] = getTimeAndDistanceBetweenStops(previousSpId, stopPoint.id)
          time_in_words = formatTime(time)
        }
        if (stopPoint.checked) {
          previousSpId = stopPoint.id
        }
        let headlined = cityNameChecker(stopPoint, i)
        return (
          <div key={i} className={(stopPoint.checked ? 'activated' : 'deactivated') + (editMode ? ' edit-mode' : '')}>
            <div className={'td' + (headlined ? ' with-headline' : '')}>
              {spNode(stopPoint, headlined)}
            </div>
            {hasFeature('costs_in_journey_patterns') && costs && <div className='costs' id={'costs-' + id + '-' + costsKey}>
              {editMode && <div>
                <p>
                  <input type="number" value={costs['distance'] || 0} min='0' name="distance" step="0.01" onChange={updateCosts} data-costs-key={costsKey} />
                  <span>km</span>
                </p>
                <p>
                  <input type="number" value={costs['time'] || 0} min='0' name="time" onChange={updateCosts} data-costs-key={costsKey} />
                  <span>min</span>
                </p>
              </div>}
              {!editMode && <div>
                <p><i className="fas fa-arrows-alt-h"></i>{formatDistance(costs['distance'] || 0)}</p>
                <p><i className="fa fa-clock"></i>{time_in_words}</p>
              </div>}
            </div>}
          </div>
        )
      })}
    </div>
  )
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
  fetchJourneyPatterns: PropTypes.func.isRequired
}
