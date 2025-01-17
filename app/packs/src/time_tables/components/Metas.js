import React from 'react'
import PropTypes from 'prop-types'

import actions from '../actions'
import ColorSelect from './ColorSelect'

const Metas = ({
  metas,
  onUpdateDayTypes,
  onUpdateComment,
  onUpdateShared,
  onUpdateColor
}) => (
  <div className='form-horizontal'>
    { metas?.errors && (
       <div className='row'>
          <div className='col-lg-12'>
            <div className="alert alert-danger mt-sm mb-sm">
              <strong> {I18n.t('error')} : </strong>
              {metas.errors.map((error, i) => {
                return (
                  <ul key={i}>
                    <li>{error}</li>
                    <br />
                  </ul>
                )
              })}
            </div>
          </div>
        </div>
    )}
    <div className="row">
      <div className="col-lg-10 col-lg-offset-1">
        {/* comment (name) */}
        <div className="form-group">
          <label htmlFor="" className="control-label col-sm-4 required">
            {I18n.t('time_tables.edit.metas.name')} <abbr title="">*</abbr>
          </label>
          <div className="col-sm-8">
            <input
              type='text'
              id='time_table_comment'
              className='form-control'
              name='time_table[comment]'
              value={metas.comment}
              required='required'
              onChange={(e) => (onUpdateComment(e.currentTarget.value))}
              />
          </div>
        </div>

        {/* shared*/}
        {metas.model_class === 'Calendar' && (
          <div className="form-group">
            <label className="col-sm-4 col-xs-5 control-label switchable_checkbox optional" htmlFor="time_table_shared">
              {I18n.attribute_name('calendar', 'shared')}
            </label>
            <div className="col-sm-8 col-xs-7">
              <div className="onoffswitch">
                <input
                  className="onoffswitch-checkbox"
                  id="time_table_shared"
                  type="checkbox"
                  checked={metas.shared}
                  name="time_table[shared]"
                  onChange={() => onUpdateShared(!metas.shared)}
                />
                <label className="onoffswitch-label" htmlFor="time_table_shared">
                  <span className="onoffswitch-inner" on={I18n.t('yes')} off={I18n.t('no')}></span>
                  <span className="onoffswitch-switch"></span>
                </label>
              </div>
            </div>
          </div>
        )}

        {/* color */}
        {metas.model_class === 'TimeTable' && <div className="form-group">
          <label htmlFor="" className="control-label col-sm-4">{I18n.attribute_name('time_table', 'color')}</label>
          <div className="col-sm-8">
            <ColorSelect selectedColor={metas.color} onUpdateColor={onUpdateColor} />
          </div>
        </div>}

        {/* calendar */}
        {metas.model_class === 'TimeTable' && <div className="form-group">
          <label htmlFor="" className="control-label col-sm-4">{I18n.attribute_name('time_table', 'calendar')}</label>
          <div className="col-sm-8">
            <span>{metas.calendar ? metas.calendar.name : I18n.t('time_tables.edit.metas.no_calendar')}</span>
          </div>
        </div>}

        {/* day_types */}
        <div className="form-group">
          <label htmlFor="" className="control-label col-sm-4">
            {I18n.t('time_tables.edit.metas.day_types')}
          </label>
          <div className="col-sm-8">
            <div className="form-group labelled-checkbox-group">
              {metas.day_types.map((day, i) =>
                <div
                  className='lcbx-group-item'
                  data-wday={'day_' + i}
                  key={i}
                >
                  <div className="checkbox">
                    <label>
                      <input
                        onChange={(e) => {onUpdateDayTypes(i, metas.day_types)}}
                        id={i}
                        type="checkbox"
                        checked={day ? 'checked' : ''}
                        />
                      <span className='lcbx-group-item-label'>{actions.weekDays()[i]}</span>
                    </label>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
)

Metas.propTypes = {
  metas: PropTypes.object.isRequired,
  onUpdateDayTypes: PropTypes.func.isRequired,
  onUpdateShared: PropTypes.func.isRequired,
  onUpdateColor: PropTypes.func.isRequired
}

export default Metas
