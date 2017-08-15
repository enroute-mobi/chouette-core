var _ = require('lodash')

const pagination = (state = {}, action) => {
  switch (action.type) {
    case 'RECEIVE_TIME_TABLES':
      return _.assign({}, state, {
        currentPage: action.json.current_periode_range,
        periode_range: action.json.periode_range,
        stateChanged: false
      })
    case 'RECEIVE_MONTH':
    case 'RECEIVE_ERRORS':
      return _.assign({}, state, {stateChanged: false})
    case 'GO_TO_PREVIOUS_PAGE':
    case 'GO_TO_NEXT_PAGE':
      let nextPage = action.nextPage ? 1 : -1
      let newPage = action.pagination.periode_range[action.pagination.periode_range.indexOf(action.pagination.currentPage) + nextPage]
      toggleOnConfirmModal()
      return _.assign({}, state, {currentPage : newPage, stateChanged: false})
    case 'CHANGE_PAGE':
      toggleOnConfirmModal()
      return _.assign({}, state, {currentPage : action.page, stateChanged: false})
    case 'INCLUDE_DATE_IN_PERIOD':
    case 'EXCLUDE_DATE_FROM_PERIOD':
    case 'DELETE_PERIOD':
    case 'VALIDATE_PERIOD_FORM':
    case 'UPDATE_COMMENT':
    case 'UPDATE_COLOR':
    case 'UPDATE_DAY_TYPES':
    case 'UPDATE_CURRENT_MONTH_FROM_DAYTYPES':
      toggleOnConfirmModal('modal')
      return _.assign({}, state, {stateChanged: true})
    default:
      return state
  }
}

const toggleOnConfirmModal = (arg = '') =>{
  $('.confirm').each(function(){
    $(this).data('toggle','')
  })
}

module.exports = pagination
