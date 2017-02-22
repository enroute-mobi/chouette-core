var React = require('react')
var PropTypes = require('react').PropTypes
var BSelect2 = require('./BSelect2')
var OlMap = require('./OlMap')

const StopPoint = (props) => {
  return (
    <div className='nested-fields'>
      <div className='wrapper'>
        <div>{props.value.user_objectid}</div>

        <div>
          <BSelect2 id={'route_stop_points_' + props.id} value={props.value} onChange={props.onChange} index={props.index} />
        </div>

        <div>
          <select className='form-control' value={props.value.for_boarding} id="for_boarding" onChange={props.onSelectChange}>
            <option value="normal">Montée autorisée</option>
            <option value="forbidden">Montée interdite</option>
          </select>
        </div>

        <div>
          <select className='form-control' value={props.value.for_alighting} id="for_alighting" onChange={props.onSelectChange}>
            <option value="normal">Descente autorisée</option>
            <option value="forbidden">Descente interdite</option>
          </select>
        </div>

        <div>
          <div className='btn-group btn-group-sm'>
            {props.value.stoparea_id &&
              <div
                className='btn btn-primary'
                onClick={props.onToggleMap}
                >
                <span className='fa fa-map-marker'></span>
              </div>
            }
            <div
              className={'btn btn-primary' + (props.first ? ' disabled' : '')}
              onClick={props.onMoveUpClick}
            >
              <span className='fa fa-arrow-up'></span>
            </div>
            <div
              className={'btn btn-primary' + (props.last ? ' disabled' : '')}
              onClick={props.onMoveDownClick}
            >
              <span className='fa fa-arrow-down'></span>
            </div>
            <div
              className='btn btn-danger delete'
              onClick={props.onDeleteClick}
            >
              <span className='fa fa-trash'></span>
            </div>
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

module.exports = StopPoint
