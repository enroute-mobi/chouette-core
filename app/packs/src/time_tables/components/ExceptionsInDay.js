import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../actions'

export default class ExceptionsInDay extends Component {
  constructor(props) {
    super(props)
  }

  handleClick() {
    const {index, day, metas: {day_types} } = this.props
    if (day.in_periods && day_types[day.wday]) {
      day.excluded_date ? this.props.onRemoveExcludedDate(index, day_types, day.date) : this.props.onAddExcludedDate(index, day_types, day.date)
    } else {
      day.include_date ? this.props.onRemoveIncludedDate(index, day_types, day.date) : this.props.onAddIncludedDate(index, day_types, day.date)
    }
  }

  render() {
    {/* display add or remove link, only if true in daytypes */}
      {/* display add or remove link, according to context (presence in period, or not) */}
      if(this.props.value.current_month[this.props.index].in_periods == true && this.props.blueDaytype == true) {
        return (
          <div className='td'>
            <button
              type='button'
              className={'btn btn-circle' + (this.props.value.current_month[this.props.index].excluded_date ? ' active' : '')}
              data-actiontype='remove'
              onClick={(e) => {
                $(e.currentTarget).toggleClass('active')
                this.handleClick()
              }}
            >
              <span className='fa fa-times'></span>
            </button>
          </div>
        )
      } else {
        return (
          <div className='td'>
            <button
              type='button'
              className={'btn btn-circle'  + (this.props.value.current_month[this.props.index].include_date ? ' active' : '')}
              data-actiontype='add'
              onClick={(e) => {
                $(e.currentTarget).toggleClass('active')
                this.handleClick()
              }}
            >
              <span className='fa fa-plus'></span>
            </button>
          </div>
        )
      // } else if(this.props.value.current_month[this.props.index].in_periods == true && this.props.blueDaytype == false){
      //   return (
      //     <div className='td'></div>
      //   )
      // } else{
      //   return false
      // }
    }
  }
}

ExceptionsInDay.propTypes = {
  value: PropTypes.object.isRequired,
  metas: PropTypes.object.isRequired,
  blueDaytype: PropTypes.bool.isRequired,
  onExcludeDateFromPeriod: PropTypes.func.isRequired,
  onIncludeDateInPeriod: PropTypes.func.isRequired,
  index: PropTypes.number.isRequired
}
