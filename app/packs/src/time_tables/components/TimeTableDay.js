import React, { Component } from 'react'
import PropTypes from 'prop-types'

export default class TimeTableDay extends Component {
  constructor(props) {
    super(props)
  }

  render() {
    return (
      <span
        className={'day' + (this.props.value.wday == 0 ? ' last_wday' : '')}
        data-wday={'S' + this.props.value.wnumber}
      >
        <span className='dayname'>
          {((this.props.value.day).charAt(0) == 'm') ? (this.props.value.day).substr(0, 2) : (this.props.value.day).charAt(0)}
        </span>
        <span
          className={'daynumber' + (((this.props.value.in_periods && this.props.dayTypeActive && !this.props.value.excluded_date) || (this.props.value.include_date)) ? ' included' : '')}
        >
          {this.props.value.mday}
        </span>
      </span>
    )
  }
}

TimeTableDay.propTypes = {
  value: PropTypes.object.isRequired,
  index: PropTypes.number.isRequired,
  dayTypeActive: PropTypes.bool.isRequired
}
