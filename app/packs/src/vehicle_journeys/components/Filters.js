import React, { useState } from 'react'
import PropTypes from 'prop-types'

import MissionSelect2 from'./tools/select2s/MissionSelect2'
import VJSelect2 from'./tools/select2s/VJSelect2'
import TimetableSelect2 from'./tools/select2s/TimetableSelect2'

export default function Filters({filters, pagination, onFilter, onResetFilters, onUpdateStartTimeFilter, onUpdateEndTimeFilter, onToggleWithoutSchedule, onToggleWithoutTimeTable, onSelect2Timetable, onSelect2JourneyPattern, onSelect2VehicleJourney, vehicleJourneys }) {
  const [filtersKey, setFiltersKey] = useState(5)
  const [isOpen, setOpen] = useState(false);
  const ToggleClass = () => {
    setOpen(!isOpen);
   };

  const resetFilters = e => {
    setFiltersKey(value => value ^ 5)
    onResetFilters(e, pagination)
  }

  const vjOptions = vehicleJourneys.reduce((options, vj) => {
    return [
      ...options,
      ...vj.objectid ? [{
        id: vj.objectid,
        text: `<div><strong>${vj.short_id} - ${vj.published_journey_name}</strong></div>`,
        isOptionSelected: filters.query.vehicleJourney?.objectid == vj.objectid,
        ...vj
      }] : []
    ]
  }, [])

  return (
    <div className='row'>
      <div className='col-lg-12'>
        <div className='form form-filter'>
          <div className='ffg-row'>
            {/* ID course */}
            <div className="form-group w33 flex items-center">
              <label htmlFor="" className="control-label col-sm-2">{I18n.t('activerecord.attributes.vehicle_journey.id') + ':'} </label>
              <div className="col-sm-10">
                <VJSelect2
                  key={filtersKey}
                  selectedItem={filters.query.vehicleJourney}
                  onSelect2VehicleJourney={onSelect2VehicleJourney}
                  isFilter={true}
                  options={vjOptions}
                />
              </div>
            </div>

            {/* Missions */}
            <div className='form-group w33 flex items-center'>
              <label htmlFor="" className="control-label col-sm-2">{I18n.t('activerecord.attributes.vehicle_journey.journey_pattern_id') + ':'}</label>
              <div className="col-sm-10">
                <MissionSelect2
                  key={filtersKey}
                  selectedItem={filters.query.journeyPattern}
                  onSelect2JourneyPattern={onSelect2JourneyPattern}
                  isFilter={true}
                />
              </div>
            </div>

            {/* Calendriers */}
            <div className='form-group w33 flex items-center'>
              <label htmlFor="" className="control-label col-sm-2">{I18n.t('activerecord.attributes.time_table.calendars') + ':'}</label>
              <div className="col-sm-10">
                <TimetableSelect2
                  key={filtersKey}
                  selectedItem={filters.query.timetable}
                  onSelect2Timetable={onSelect2Timetable}
                  isFilter={true}
                  />
              </div>
            </div>
          </div>

          <div className='ffg-row'>
            {/* Plage horaire */}
            <div className={'form-group togglable' + (isOpen ? " open" : "")} onClick={ToggleClass}>
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
              className='btn btn-cancel'
              onClick={resetFilters}>
              {I18n.t('actions.erase')}
            </span>
            <span
              className='btn btn-default'
              onClick={(e) => onFilter(e, pagination)}>
              {I18n.t('actions.filter')}
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