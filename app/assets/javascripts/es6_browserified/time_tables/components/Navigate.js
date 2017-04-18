var React = require('react')
var Component = require('react').Component
var PropTypes = require('react').PropTypes
var actions = require('../actions')
var _ = require('lodash')

let Navigate = ({ dispatch, metas, timetable, pagination, status, filters}) => {
  if(status.isFetching == true) {
    return false
  }
  if(status.fetchSuccess == true) {
    let pageIndex = pagination.periode_range.indexOf(pagination.currentPage)
    let firstPage = pageIndex == 0
    let lastPage = pageIndex == pagination.periode_range.length - 1
    return (
      <div className="pagination">

        <form className='page_links' onSubmit={e => {e.preventDefault()}}>
          <select
            value={pagination.currentPage}
            onChange={()=>{}}
          >
            {_.map(pagination.periode_range, (month, i) => (
              <option
                value={month}
                key={i}
              >
                {actions.monthName(month) + ' ' + new Date(month).getFullYear()}
              </option>
              )
            )}
          </select>
          <button
            onClick={e => {
              e.preventDefault()
                  dispatch(actions.checkConfirmModal(e, actions.goToPreviousPage(dispatch, pagination), pagination.stateChanged, dispatch))
            }}
            type='button'
            data-target='#ConfirmModal'
            className={(firstPage ? 'disabled ' : '') + 'previous_page'}
            disabled={(firstPage ? 'disabled' : '')}
          ></button>
          <button
            onClick={e => {
              e.preventDefault()
                  dispatch(actions.checkConfirmModal(e, actions.goToNextPage(dispatch, pagination), pagination.stateChanged, dispatch))
            }}
            type='button'
            data-target='#ConfirmModal'
            className={(lastPage ? 'disabled ' : '') + 'next_page'}
            disabled={(lastPage ? 'disabled' : '')}
          ></button>
        </form>
      </div>
    )
  } else {
    return false
  }
}

Navigate.propTypes = {
  status: PropTypes.object.isRequired,
  pagination: PropTypes.object.isRequired,
  dispatch: PropTypes.func.isRequired
}

module.exports = Navigate
