import React, { Component } from 'react'
import PropTypes from 'prop-types'
import actions from '../actions'

export default class SaveTimetable extends Component{
  constructor(props){
    super(props)
  }

  render() {
    const error = actions.errorModalKey(this.props.timetable.time_table_periods, this.props.metas.day_types)

    return (
      <div className='row mt-md'>
        <div className='col-lg-12 text-right'>
          <form className='time_tables formSubmitr ml-xs' onSubmit={e => {e.preventDefault()}}>
            <button
              className='btn btn-default'
              type='button'
              onClick={e => {
                e.preventDefault()
                if (error) {
                  this.props.onShowErrorModal(error)
                } else {
                  actions.submitTimetable(this.props.getDispatch(), this.props.timetable, this.props.metas)
                }
              }}
            >
              {I18n.t('actions.submit')}
            </button>
          </form>
        </div>
      </div>
    )
  }
}

SaveTimetable.propTypes = {
  timetable: PropTypes.object.isRequired,
  status: PropTypes.object.isRequired,
  metas: PropTypes.object.isRequired
}