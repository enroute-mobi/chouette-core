import React, { Component } from 'react'
import PropTypes from 'prop-types'
import capitalize from 'lodash/capitalize'
import actions from '../actions'

export default function Navigate({ dispatch, journeyPatterns, pagination, status }) {
  let firstPage = 1
  let lastPage = Math.ceil(pagination.totalCount / window.journeyPatternsPerPage)

  let firstItemOnPage = firstPage + (pagination.perPage * (pagination.page - firstPage))
  let lastItemOnPage = firstItemOnPage + (pagination.perPage - firstPage)

  if(status.isFetching == true) {
    return false
  }
  if(status.fetchSuccess == true) {
    return (
      <div className='row'>
        <div className='col-lg-12 text-right'>
          <div className='pagination'>
            {I18n.t('will_paginate.page_entries_info.multi_page', { model: capitalize(I18n.model_name('journey_pattern', { plural: true })), from: firstItemOnPage, to: lastItemOnPage, count: pagination.totalCount})}
            <form className='page_links' onSubmit={e => {
                e.preventDefault()
              }}>
              <button
                onClick={e => {
                  e.preventDefault()
                  dispatch(actions.checkConfirmModal(e, actions.goToPreviousPage(dispatch, pagination), pagination.stateChanged, dispatch))
                }}
                type='button'
                data-toggle=''
                data-target='#ConfirmModal'
                className={'previous_page' + (pagination.page == firstPage ? ' disabled' : '')}
                disabled={(pagination.page == firstPage ? ' disabled' : '')}
              >
              </button>
              <button
                onClick={e => {
                  e.preventDefault()
                  dispatch(actions.checkConfirmModal(e, actions.goToNextPage(dispatch, pagination), pagination.stateChanged, dispatch))
                }}
                type='button'
                data-toggle=''
                data-target='#ConfirmModal'
                className={'next_page' + (pagination.page == lastPage ? ' disabled' : '')}
                disabled={(pagination.page == lastPage ? 'disabled' : '')}
              >
              </button>
            </form>
          </div>
        </div>
      </div>
    )
  } else {
    return false
  }
}

Navigate.propTypes = {
  journeyPatterns: PropTypes.array.isRequired,
  status: PropTypes.object.isRequired,
  pagination: PropTypes.object.isRequired,
  dispatch: PropTypes.func.isRequired
}