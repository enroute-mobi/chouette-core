import React, { Component } from 'react'
import PropTypes from 'prop-types'
import PeriodManager from './PeriodManager'

export default class PeriodsInDay extends Component {
  constructor(props) {
    super(props)
  }

  isIn(date) {
    let currentDate = date.getTime()
    let cls = 'td'
    let periods = this.props.value

    periods.map((p, i) => {
      if (!p.deleted){
        let begin = new Date(p.period_start).getTime()
        let end = new Date(p.period_end).getTime()

        if(currentDate >= begin && currentDate <= end) {
          if(currentDate == begin) {
            cls += ' in_periods start_period'
          } else if(currentDate == end) {
            cls += ' in_periods end_period'
          } else {
            cls += ' in_periods'
          }
        }
      }
    })
    return cls
  }

  render() {
    return (
      <div
        className={this.isIn(this.props.currentDate) + (this.props.metas.day_types[this.props.day.wday] || !this.props.day.in_periods ? '' : ' out_from_daytypes')}
      >
        {this.props.value.map((p, i) => {
          if(!p.deleted){
            let begin = new Date(p.period_start).getTime()
            let end = new Date(p.period_end).getTime()
            let d = this.props.currentDate.getTime()

            if(d >= begin && d <= end) {
              if(d == begin || (this.props.currentDate.getUTCDate() == 1)) {
                return (
                  <PeriodManager
                    key={i}
                    index={i}
                    value={p}
                    metas={this.props.metas}
                    currentDate={this.props.currentDate}
                    onDeletePeriod={this.props.onDeletePeriod}
                    onOpenEditPeriodForm={this.props.onOpenEditPeriodForm}
                  />
                )
              } else {
                return false
              }
            }
          }else{
            return false
          }
        })}
      </div>
    )
  }
}

PeriodsInDay.propTypes = {
  value: PropTypes.array.isRequired,
  currentDate: PropTypes.object.isRequired,
  index: PropTypes.number.isRequired,
  onDeletePeriod: PropTypes.func.isRequired
}
