import React from 'react'
import PropTypes from 'prop-types'

import MissionSelect2 from'./tools/select2s/MissionSelect2'
import VJSelect2 from'./tools/select2s/VJSelect2'
import TimetableSelect2 from'./tools/select2s/TimetableSelect2'

export default function Filters({filters, pagination, missions, onFilter, onResetFilters, onUpdateStartTimeFilter, onUpdateEndTimeFilter, onToggleWithoutSchedule, onToggleWithoutTimeTable, onSelect2Timetable, onSelect2JourneyPattern, onSelect2VehicleJourney}) {
  return (
    <div className='row'>
      <div className='col-lg-12'>
        <div className='form form-filter'>
          <div className='ffg-row'>
            {/* ID course */}
            <div className="form-group w33">
              <VJSelect2
                onSelect2VehicleJourney={onSelect2VehicleJourney}
                filters={filters}
                isFilter={true}
                />
            </div>

            {/* Missions */}
            <div className='form-group w33'>
              <MissionSelect2
                onSelect2JourneyPattern={onSelect2JourneyPattern}
                filters={filters}
                isFilter={true}
                values={missions}
                />
            </div>

            {/* Calendriers */}
            <div className='form-group w33'>
              <TimetableSelect2
                onSelect2Timetable={onSelect2Timetable}
                hasRoute={true}
                chunkURL={("/autocomplete_time_tables.json?route_id=" + String(window.route_id))}
                searchKey={"unaccented_comment_or_objectid_cont_any"}
                filters={filters}
                isFilter={true}
                />
            </div>
          </div>

          <div className='ffg-row'>
            {/* Plage horaire */}
            <div className='form-group togglable'>
              <label className='control-label'>{I18n.t("vehicle_journeys.form.departure_range.label")}</label>
              <div className='filter_menu'>
                <div className='form-group time filter_menu-item'>
                  <label className='control-label time'>{I18n.t("vehicle_journeys.form.departure_range.start")}</label>
                  <div className='form-inline'>
                    <div className='input-group time'>
                      <input
                        type='number'
                        className='form-control'
                        min='00'
                        max='23'
                        onChange={(e) => {onUpdateStartTimeFilter(e, 'hour')}}
                        value={filters.query.interval.start.hour}
                        />
                      <span>:</span>
                      <input
                        type='number'
                        className='form-control'
                        min='00'
                        max='59'
                        onChange={(e) => {onUpdateStartTimeFilter(e, 'minute')}}
                        value={filters.query.interval.start.minute}
                        />
                    </div>
                  </div>
                </div>
                <div className='form-group time filter_menu-item'>
                  <label className='control-label time'>{I18n.t("vehicle_journeys.form.departure_range.end")}</label>
                  <div className='form-inline'>
                    <div className='input-group time'>
                      <input
                        type='number'
                        className='form-control'
                        min='00'
                        max='23'
                        onChange={(e) => {onUpdateEndTimeFilter(e, 'hour')}}
                        value={filters.query.interval.end.hour}
                        />
                      <span>:</span>
                      <input
                        type='number'
                        className='form-control'
                        min='00'
                        max='59'
                        onChange={(e) => {onUpdateEndTimeFilter(e, 'minute')}}
                        value={filters.query.interval.end.minute}
                        />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Switch avec/sans horaires */}
            <div className='form-group has_switch'>
              <label className='control-label pull-left'>{I18n.t("vehicle_journeys.form.show_journeys_without_schedule")}</label>
              <div className='form-group pull-left' style={{padding: 0}}>
                <div className='checkbox'>
                  <label>
                    <input
                      type='checkbox'
                      onChange={onToggleWithoutSchedule}
                      checked={filters.query.withoutSchedule}
                      ></input>
                    <span className='switch-label' data-checkedvalue={I18n.t("no")} data-uncheckedvalue={I18n.t("yes")}>
                      {filters.query.withoutSchedule ? I18n.t("yes") : I18n.t("no")}
                    </span>
                  </label>
                </div>
              </div>
            </div>
          </div>

          <div className="ffg-row">
            {/* Switch avec/sans calendrier */}
            <div className='form-group has_switch'>
              <label className='control-label pull-left'>{I18n.t("vehicle_journeys.form.show_journeys_with_calendar")}</label>
              <div className='form-group pull-left' style={{padding: 0}}>
                <div className='checkbox'>
                  <label>
                    <input
                      type='checkbox'
                      onChange={onToggleWithoutTimeTable}
                      checked={filters.query.withoutTimeTable}
                      ></input>
                    <span className='switch-label' data-checkedvalue={I18n.t("no")} data-uncheckedvalue={I18n.t("yes")}>
                      {filters.query.withoutTimeTable ? I18n.t("yes") : I18n.t("no")}
                    </span>
                  </label>
                </div>
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className='actions'>
            <span
              className='btn btn-link'
              onClick={(e) => onResetFilters(e, pagination)}>
              Effacer
            </span>
            <span
              className='btn btn-default'
              onClick={(e) => onFilter(e, pagination)}>
              Filtrer
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

Filters.propTypes = {
  filters : PropTypes.object.isRequired,
  pagination : PropTypes.object.isRequired,
  onFilter: PropTypes.func.isRequired,
  onResetFilters: PropTypes.func.isRequired,
  onUpdateStartTimeFilter: PropTypes.func.isRequired,
  onUpdateEndTimeFilter: PropTypes.func.isRequired,
  onSelect2Timetable: PropTypes.func.isRequired,
  onSelect2JourneyPattern: PropTypes.func.isRequired,
  onSelect2VehicleJourney: PropTypes.func.isRequired
}
