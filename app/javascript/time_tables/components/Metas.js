import React from 'react'
import PropTypes from 'prop-types'

import actions from '../actions'
import TagsSelect2 from './TagsSelect2'

export default function Metas({metas, onUpdateDayTypes, onUpdateComment, onUpdateColor, onSelect2Tags, onUnselect2Tags}, {I18n}) {
  let colorList = ["", "#9B9B9B", "#FFA070", "#C67300", "#7F551B", "#41CCE3", "#09B09C", "#3655D7",   "#6321A0", "#E796C6", "#DD2DAA"]
  return (
    <div className='form-horizontal'>
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
                className='form-control'
                value={metas.comment}
                required='required'
                onChange={(e) => (onUpdateComment(e.currentTarget.value))}
                />
            </div>
          </div>

          {/* color */}
          {metas.color !== undefined && <div className="form-group">
            <label htmlFor="" className="control-label col-sm-4">{I18n.attribute_name('time_table', 'color')}</label>
            <div className="col-sm-8">
              <div className="dropdown color_selector">
                <button
                  type='button'
                  className="btn btn-default dropdown-toggle"
                  id='dpdwn_color'
                  data-toggle='dropdown'
                  aria-haspopup='true'
                  aria-expanded='true'
                  >
                  <span
                    className='fa fa-circle mr-xs'
                    style={{color: (metas.color == '')  ? 'transparent' : metas.color}}
                    ></span>
                  <span className='caret'></span>
                </button>

                <div className="form-group dropdown-menu" aria-labelledby='dpdwn_color'>
                  {colorList.map((c, i) =>
                    <span
                      className="radio"
                      key={i}
                      onClick={() => {onUpdateColor(c)}}
                    >
                      <label htmlFor="">
                        <input
                          type='radio'
                          className='color_selector'
                          value={c}
                          />
                        <span
                          className='fa fa-circle'
                          style={{color: ((c == '') ? 'transparent' : c)}}
                          ></span>
                      </label>
                    </span>
                  )}
                </div>
              </div>
            </div>
          </div>}

          {/* tags */}
          {metas.tags !== undefined && <div className="form-group">
            <label htmlFor="" className="control-label col-sm-4">{I18n.attribute_name('time_table', 'tag_list')}</label>
            <div className="col-sm-8">
              <TagsSelect2
                initialTags={metas.initial_tags}
                tags={metas.tags}
                onSelect2Tags={(e) => onSelect2Tags(e)}
                onUnselect2Tags={(e) => onUnselect2Tags(e)}
              />
            </div>
          </div>}

          {/* calendar */}
          {metas.calendar !== null && <div className="form-group">
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
}

Metas.propTypes = {
  metas: PropTypes.object.isRequired,
  onUpdateDayTypes: PropTypes.func.isRequired,
  onUpdateColor: PropTypes.func.isRequired,
  onUpdateColor: PropTypes.func.isRequired,
  onSelect2Tags: PropTypes.func.isRequired,
  onUnselect2Tags: PropTypes.func.isRequired
}

Metas.contextTypes = {
  I18n: PropTypes.object
}
