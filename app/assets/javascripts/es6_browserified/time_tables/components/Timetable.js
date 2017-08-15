var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes
var TimeTableDay = require('./TimeTableDay')
var PeriodsInDay = require('./PeriodsInDay')
var ExceptionsInDay = require('./ExceptionsInDay')
var actions = require('../actions')

class Timetable extends Component{
  constructor(props){
    super(props)
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
              <div className="strong">Synthèse</div>
            </div>
            <div className="td"><span>Journées d'application</span></div>
            <div className="td"><span>Périodes</span></div>
            <div className="td"><span>Exceptions</span></div>
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
                    className={'td-group' + (this.props.metas.day_types[d.wday] || !d.in_periods ? '' : ' out_from_daytypes') + (d.wday == 0 ? ' last_wday' : '')}
                  >
                    {/* day_types */}
                    <div className="td"></div>

                    {/* periods */}
                    <PeriodsInDay
                      index={i}
                      value={this.props.timetable.time_table_periods}
                      currentDate={this.currentDate(this.props.timetable.current_periode_range, d.mday)}
                      onDeletePeriod={this.props.onDeletePeriod}
                      onOpenEditPeriodForm={this.props.onOpenEditPeriodForm}
                      metas={this.props.metas}
                    />

                    {/* exceptions */}
                    <ExceptionsInDay
                      index={i}
                      value={this.props.timetable}
                      currentDate={d.date}
                      metas={this.props.metas}
                      blueDaytype={this.props.metas.day_types[d.wday]}
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

module.exports = Timetable
