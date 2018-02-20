import React from 'react'
import PropTypes from 'prop-types'

import BSelect2 from './BSelect2'
import OlMap from './OlMap'

export default function StopPoint(props, {I18n}) {
  return (
    <div className='nested-fields'>
      <div className='wrapper'>
        <div style={{width: 90}}>
          <span>{props.value.user_objectid}</span>
        </div>

        <div>
          <BSelect2 id={'route_stop_points_' + props.id} value={props.value} onChange={props.onChange} index={props.index} />
        </div>

        <div>
          <select className='form-control' value={props.value.for_boarding} id="for_boarding" onChange={props.onSelectChange}>
            <option value="normal">{I18n.t('routes.edit.stop_point.boarding.normal')}</option>
            <option value="forbidden">{I18n.t('routes.edit.stop_point.boarding.forbidden')}</option>
          </select>
        </div>

        <div>
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
            onClick={props.onMoveUpClick}
          >
            <span className='fa fa-arrow-up'></span>
          </div>
          <div
            className={'btn btn-link' + (props.last ? ' disabled' : '')}
            onClick={props.onMoveDownClick}
          >
            <span className='fa fa-arrow-down'></span>
          </div>

          <div
            className='btn btn-link'
            onClick={props.onToggleEdit}
            >
            <span className={'fa' + (props.value.edit ? ' fa-check' : ' fa-pencil')}></span>
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

StopPoint.contextTypes = {
  I18n: PropTypes.object
}
