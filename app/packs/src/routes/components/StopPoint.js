import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames'

import BSelect2 from './BSelect2'
import OlMap from './OlMap'

import { defaultAttribute } from '../actions'

export default function StopPoint(props) {
  var isFlexible = props.value.flexible

  return (
    <div className={classNames('nested-fields', { 'flexible-stop-point': isFlexible })}>
      <div className='wrapper'>
        <div style={{width: 40}}>
          <div className="form-group">
            {isFlexible && <i className="fa fa-phone"></i>}
          </div>
        </div>

        <div style={{width: 100}}>
          <div className="form-group">
            <div>{props.value.user_objectid || '-'}</div>
          </div>
        </div>
        <div style={{width: 250}}>
          <BSelect2 id={props.id} value={props.value} onChange={props.onChange} index={props.index} hasError={props.hasError} autocompleteUrl={`/autocomplete_stop_areas.json${isFlexible ? '': '?without_flexible_stop_place=true'}`} />
        </div>

        <div style={{width: 120}}>
          <select className='form-control' value={props.value.for_boarding} id="for_boarding" onChange={props.onSelectChange}>
            <option value="normal">{I18n.t('routes.edit.stop_point.boarding.normal')}</option>
            <option value="forbidden">{I18n.t('routes.edit.stop_point.boarding.forbidden')}</option>
          </select>
        </div>

        <div style={{width: 120}}>
          <select className='form-control' value={props.value.for_alighting} id="for_alighting" onChange={props.onSelectChange}>
            <option value="normal">{I18n.t('routes.edit.stop_point.alighting.normal')}</option>
            <option value="forbidden">{I18n.t('routes.edit.stop_point.alighting.forbidden')}</option>
          </select>
        </div>

        <div className='actions-5'>
          <div
            className={'btn btn-link' + (props.value.stoparea_id ? '' : ' disabled')}
            onClick={props.onToggleMap}
            >
            <span className='fa fa-map-marker'></span>
          </div>

          <div
            className={'btn btn-link' + (props.first ? ' disabled' : '')}
            onClick={props.first ? null : props.onMoveUpClick}
          >
            <span className='fa fa-arrow-up'></span>
          </div>
          <div
            className={'btn btn-link' + (props.last ? ' disabled' : '')}
            onClick={props.last ? null : props.onMoveDownClick}
          >
            <span className='fa fa-arrow-down'></span>
          </div>

          <div
            className='btn btn-link'
            onClick={props.onToggleEdit}
            >
            <span className={'fa' + (props.value.edit ? ' fa-check' : ' fa-pencil-alt')}></span>
          </div>
          <div
            className='btn btn-link'
            onClick={props.onDeleteClick}
          >
            <span className='fa fa-trash text-danger'></span>
          </div>
        </div>
      </div>

      <OlMap
        value = {props.value}
        index = {props.index}
        onSelectMarker = {props.onSelectMarker}
        onUnselectMarker = {props.onUnselectMarker}
        onUpdateViaOlMap = {props.onUpdateViaOlMap}
      />
    </div>
  )
}

StopPoint.propTypes = {
  onToggleMap: PropTypes.func.isRequired,
  onToggleEdit: PropTypes.func.isRequired,
  onDeleteClick: PropTypes.func.isRequired,
  onMoveUpClick: PropTypes.func.isRequired,
  onMoveDownClick: PropTypes.func.isRequired,
  onChange: PropTypes.func.isRequired,
  onSelectChange: PropTypes.func.isRequired,
  first: PropTypes.bool,
  last: PropTypes.bool,
  index: PropTypes.number,
  value: PropTypes.object
}
