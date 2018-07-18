import React, { Component } from 'react'
import PropTypes from 'prop-types'
import map from 'lodash/map'
import actions from '../actions'

export default function Navigate({ dispatch, metas, timetable, pagination, status, filters}) {
  if(status.isFetching == true) {
    return false
  }
  if(status.fetchSuccess == true) {
    let pageIndex = pagination.periode_range.indexOf(pagination.currentPage)
    let firstPage = pageIndex == 0
    let lastPage = pageIndex == pagination.periode_range.length - 1

    monthSelectScrollHandler()
    return (
      <div className="pagination pull-right">
        <form className='form-inline' onSubmit={e => {e.preventDefault()}}>
          {/* date selector */}
          <div className="form-group">
            <div className="dropdown month_selector" style={{display: 'inline-block'}}>
              <div
                className='btn btn-default dropdown-toggle'
                id='date_selector'
                data-toggle='dropdown'
                aria-haspopup='true'
                aria-expanded='true'
              >
                {pagination.currentPage ? (actions.monthName(pagination.currentPage) + ' ' + new Date(pagination.currentPage).getUTCFullYear()) : ''}
                <span className='caret'></span>
              </div>
              <ul
                id='month-list'
                className='dropdown-menu'
                aria-labelledby='date_selector'
              >
                {map(pagination.periode_range, (month, i) => (
                  <li key={i}> 
                    <button
                      id={month == pagination.currentPage ? 'selectedMonth' : ''} 
                      type='button'
                      value={month}
                      onClick={e => {
                        e.preventDefault()
                        dispatch(actions.checkConfirmModal(e, actions.changePage(dispatch, e.currentTarget.value), pagination.stateChanged, dispatch, metas, timetable))
                      }}
                    >
                      {actions.monthName(month) + ' ' + new Date(month).getUTCFullYear()}
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          {/* prev/next */}
          <div className="form-group">
            <div className="page_links">
              <button
                onClick={e => {
                  e.preventDefault()
                  dispatch(actions.checkConfirmModal(e, actions.goToPreviousPage(dispatch, pagination), pagination.stateChanged, dispatch, metas, timetable))
                }}
                type='button'
                data-target='#ConfirmModal'
                className={(firstPage ? 'disabled ' : '') + 'previous_page'}
                disabled={(firstPage ? 'disabled' : '')}
                ></button>
              <button
                onClick={e => {
                  e.preventDefault()
                  dispatch(actions.checkConfirmModal(e, actions.goToNextPage(dispatch, pagination), pagination.stateChanged, dispatch, metas, timetable))
                }}
                type='button'
                data-target='#ConfirmModal'
                className={(lastPage ? 'disabled ' : '') + 'next_page'}
                disabled={(lastPage ? 'disabled' : '')}
                ></button>
            </div>
          </div>
        </form>
      </div>
    )
  } else {
    return false
  }
}

let monthSelectScrollHandler = () => {
  $(document).ready(() => {
    $('.month_selector').on('shown.bs.dropdown', () => {
      let monthTopPosition = $('#month-list').find('li > button#selectedMonth').position().top
      $('#month-list').scrollTop(monthTopPosition)
    })

    $('.month_selector').on('hide.bs.dropdown', () => $('#month-list').scrollTop(0) )
  })  
}

Navigate.propTypes = {
  status: PropTypes.object.isRequired,
  pagination: PropTypes.object.isRequired,
  dispatch: PropTypes.func.isRequired
}
