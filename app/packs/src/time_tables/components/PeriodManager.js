import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../actions'

export default class PeriodManager extends Component {
  constructor(props, context) {
    super(props, context)
  }

  toEndPeriod(curr, end) {
    let diff

    let startCurrM = curr.split('-')[1]
    let endPeriodM = end.split('-')[1]

    let lastDayInM = new Date(curr.split('-')[2], startCurrM + 1, 0)
    lastDayInM = lastDayInM.toJSON().substr(0, 10).split('-')[2]

    if(startCurrM === endPeriodM) {
      diff = (end.split('-')[2] - curr.split('-')[2])
    } else {
      diff = (lastDayInM - curr.split('-')[2])
    }

    return diff
  }

  render() {
    return (
      <div
        className='period_manager'
        id={this.props.value.id}
        data-toendperiod={this.toEndPeriod(this.props.currentDate.toJSON().substr(0, 10),  this.props.value.period_end)}
      >
        <p className='strong'>
          {actions.getLocaleDate(this.props.value.period_start) + ' > ' + actions.getLocaleDate(this.props.value.period_end)}
        </p>

        <div className='dropdown'>
          <div
            className='btn dropdown-toggle'
            id='period_actions'
            data-toggle='dropdown'
            aria-haspopup='true'
            aria-expanded='true'
          >
            <span className='fa fa-cog'></span>
          </div>
          <ul
            className='dropdown-menu'
            aria-labelledby='date_selector'
          >
            <li>
              <button
                type='button'
                onClick={() => this.props.onOpenEditPeriodForm(this.props.value, this.props.index)}
              >
                {I18n.t('actions.edit')}
              </button>
            </li>
            <li className='delete-action'>
              <button
                type='button'
                onClick={() => this.props.onDeletePeriod(this.props.index, this.props.metas.day_types)}
              >
                <span className='fa fa-trash'></span>
                {I18n.t('actions.destroy')}
              </button>
            </li>
          </ul>
        </div>
      </div>
    )
  }
}

PeriodManager.propTypes = {
  value: PropTypes.object.isRequired,
  currentDate: PropTypes.object.isRequired,
  onDeletePeriod: PropTypes.func.isRequired,
  onOpenEditPeriodForm: PropTypes.func.isRequired
}
