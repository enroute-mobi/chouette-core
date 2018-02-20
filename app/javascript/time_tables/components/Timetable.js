import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../actions'
import TimeTableDay from './TimeTableDay'
import PeriodsInDay from './PeriodsInDay'
import ExceptionsInDay from './ExceptionsInDay'


export default class Timetable extends Component {
  constructor(props, context){
    super(props, context)
  }

  currentDate(mFirstday, day) {
    let currentMonth = mFirstday.split('-')
    let twodigitsDay = day < 10 ? ('0' + day) : day
    let currentDate = new Date(currentMonth[0] + '-' + currentMonth[1] + '-' + twodigitsDay)

    return currentDate
  }

  render() {
    if(this.props.status.isFetching == true) {
      return (
        <div className="isLoading" style={{marginTop: 80, marginBottom: 80}}>
          <div className="loader"></div>
        </div>
      )
    } else {
      return (
        <div className="table table-2entries mb-sm">
          <div className="t2e-head w20">
            <div className="th">
              <div className="strong">{this.context.I18n.t('time_tables.edit.synthesis')}</div>
            </div>
            <div className="td"><span>{this.context.I18n.t('time_tables.edit.day_types')}</span></div>
            <div className="td"><span>{this.context.I18n.t('time_tables.edit.periods')}</span></div>
            <div className="td"><span>{this.context.I18n.t('time_tables.edit.exceptions')}</span></div>
          </div>
          <div className="t2e-item-list w80">
            <div>
              <div className="t2e-item">
                <div className="th">
                  <div className="strong monthName">
                    {actions.monthName(this.props.timetable.current_periode_range)}
                  </div>

                  <div className='monthDays'>
                    {this.props.timetable.current_month.map((d, i) =>
                      <TimeTableDay
                        key={i}
                        index={i}
                        value={d}
                        dayTypeActive={this.props.metas.day_types[d.wday]}
                        />
                    )}
                  </div>
                </div>

                {this.props.timetable.current_month.map((d, i) =>
                  <div
                    key={i}
                    className={'td-group'+ (d.wday == 0 ? ' last_wday' : '')}
                  >
                    {/* day_types */}
                    <div className={"td" + (this.props.metas.day_types[d.wday] || !d.in_periods ? '' : ' out_from_daytypes') }></div>

                    {/* periods */}
                    <PeriodsInDay
                      day={d}
                      index={i}
                      value={this.props.timetable.time_table_periods}
                      currentDate={this.currentDate(this.props.timetable.current_periode_range, d.mday)}
                      onDeletePeriod={this.props.onDeletePeriod}
                      onOpenEditPeriodForm={this.props.onOpenEditPeriodForm}
                      metas={this.props.metas}
                    />

                    {/* exceptions */}
                    <ExceptionsInDay
                      day={d}
                      index={i}
                      value={this.props.timetable}
                      currentDate={d.date}
                      metas={this.props.metas}
                      blueDaytype={this.props.metas.day_types[d.wday]}
                      onAddIncludedDate={this.props.onAddIncludedDate}
                      onRemoveIncludedDate={this.props.onRemoveIncludedDate}
                      onAddExcludedDate={this.props.onAddExcludedDate}
                      onRemoveExcludedDate={this.props.onRemoveExcludedDate}
                      onExcludeDateFromPeriod={this.props.onExcludeDateFromPeriod}
                      onIncludeDateInPeriod={this.props.onIncludeDateInPeriod}
                    />
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )
    }
  }
}

Timetable.propTypes = {
  metas: PropTypes.object.isRequired,
  timetable: PropTypes.object.isRequired,
  status: PropTypes.object.isRequired,
  onDeletePeriod: PropTypes.func.isRequired,
  onExcludeDateFromPeriod: PropTypes.func.isRequired,
  onIncludeDateInPeriod: PropTypes.func.isRequired
}

Timetable.contextTypes = {
  I18n: PropTypes.object
}
