import React, { Component } from 'react'
import PropTypes from 'prop-types'
import capitalize from 'lodash/capitalize'
import actions from'../actions'

export default function Navigate({ dispatch, vehicleJourneys, pagination, status, filters}) {
  let firstPage = 1
  let lastPage = Math.ceil(pagination.totalCount / pagination.perPage)
  let minVJ = (pagination.page - 1) * pagination.perPage + 1
  if (pagination.totalCount == 0){
    minVJ = 0
    lastPage = 1
  }
  let maxVJ = Math.min((pagination.page * pagination.perPage), pagination.totalCount)
  if(status.isFetching == true) {
    return false
  }
  if(status.fetchSuccess == true) {
    return (
      <div className="pagination">
        {I18n.t('will_paginate.page_entries_info.multi_page', { model: capitalize(I18n.model_name('vehicle_journey', { plural: true })), from: minVJ, to: maxVJ, count: pagination.totalCount })}
        <form className='page_links' onSubmit={e => {e.preventDefault()}}>
          <button
            onClick={e => {
              e.preventDefault()
              dispatch(actions.checkConfirmModal(e, actions.goToPreviousPage(dispatch, pagination, filters.queryString), pagination.stateChanged, dispatch))
            }}
            type='button'
            data-target='#ConfirmModal'
            className={(pagination.page == firstPage ? 'disabled ' : '') + 'previous_page'}
            disabled={(pagination.page == firstPage ? 'disabled' : '')}
          ></button>
          <button
            onClick={e => {
              e.preventDefault()
              dispatch(actions.checkConfirmModal(e, actions.goToNextPage(dispatch, pagination, filters.queryString), pagination.stateChanged, dispatch))
            }}
            type='button'
            data-target='#ConfirmModal'
            className={(pagination.page == lastPage ? 'disabled ' : '') + 'next_page'}
            disabled={(pagination.page == lastPage ? 'disabled' : '')}
          ></button>
        </form>
      </div>
    )
  } else {
    return false
  }
}

Navigate.propTypes = {
  vehicleJourneys: PropTypes.array.isRequired,
  status: PropTypes.object.isRequired,
  pagination: PropTypes.object.isRequired,
  dispatch: PropTypes.func.isRequired
}
