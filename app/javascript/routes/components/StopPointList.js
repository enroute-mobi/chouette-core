import React from 'react'
import PropTypes from 'prop-types'

import StopPoint from './StopPoint'

export default function StopPointList({ stopPoints, onDeleteClick, onMoveUpClick, onMoveDownClick, onChange, onSelectChange, onToggleMap, onToggleEdit, onSelectMarker, onUnselectMarker, onUpdateViaOlMap, errors }) {
  return (
    <div className='subform'>
      { errors.invalidLength && (
        <div className="alert alert-danger">
          <span className="fa fa-lg fa-exclamation-circle"></span>
          <span>{I18n.t('activerecord.errors.models.route.attributes.stop_points.not_enough_stop_points')}</span>
        </div>
      ) }
      <div className='nested-head'>
        <div className="wrapper">
          <div style={{width: 100}}>
            <div className="form-group">
              <label className="control-label">{I18n.t('simple_form.labels.stop_point.reflex_id')}</label>
            </div>
          </div>
          <div style={{width: 250}}>
            <div className="form-group">
              <label className="control-label">{I18n.t('simple_form.labels.stop_point.name')}</label>
            </div>
          </div>
          <div style={{width: 120}}>
            <div className="form-group">
              <label className="control-label">{I18n.t('simple_form.labels.stop_point.for_boarding')}</label>
            </div>
          </div>
          <div style={{width: 120}}>
            <div className="form-group">
              <label className="control-label">{I18n.t('simple_form.labels.stop_point.for_alighting')}</label>
            </div>
          </div>
          <div className='actions-5'></div>
        </div>
      </div>
      {stopPoints.map((stopPoint, index) =>
        <StopPoint
          id={`route_stop_point_${index + 1}`}
          key={'item-' + index}
          onDeleteClick={() => onDeleteClick(index, stopPoint.stoppoint_id)}
          onMoveUpClick={() => {
            onMoveUpClick(index)
          }}
          onMoveDownClick={() => onMoveDownClick(index)}
          onChange={ onChange }
          onSelectChange={ (e) => onSelectChange(e, index) }
          onToggleMap={() => onToggleMap(index)}
          onToggleEdit={() => onToggleEdit(index)}
          onSelectMarker={onSelectMarker}
          onUnselectMarker={onUnselectMarker}
          onUpdateViaOlMap={onUpdateViaOlMap}
          first={ index === 0 }
          last={ index === (stopPoints.length - 1) }
          index={ index }
          value={ stopPoint }
          hasError={errors.invalidStopPointIndexes.includes(index)}
        />
      )}
    </div>
  )
}

StopPointList.propTypes = {
  stopPoints: PropTypes.array.isRequired,
  onDeleteClick: PropTypes.func.isRequired,
  onMoveUpClick: PropTypes.func.isRequired,
  onMoveDownClick: PropTypes.func.isRequired,
  onSelectChange: PropTypes.func.isRequired,
  onSelectMarker: PropTypes.func.isRequired,
  onUnselectMarker : PropTypes.func.isRequired
}

StopPointList.contextTypes = {
  I18n: PropTypes.object
}
