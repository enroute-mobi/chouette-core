import assign from 'lodash/assign'

export default function pagination(state = {}, action) {
  switch (action.type) {
    case 'RECEIVE_TIME_TABLES':
      return assign({}, state, {
        currentPage: action.json.current_periode_range,
        periode_range: action.json.periode_range,
        stateChanged: false
      })
    case 'RECEIVE_MONTH':
    case 'RECEIVE_ERRORS':
      return assign({}, state, {stateChanged: false})
    case 'GO_TO_PREVIOUS_PAGE':
    case 'GO_TO_NEXT_PAGE':
      let nextPage = action.nextPage ? 1 : -1
      let newPage = action.pagination.periode_range[action.pagination.periode_range.indexOf(action.pagination.currentPage) + nextPage]
      toggleOnConfirmModal()
      return assign({}, state, {currentPage : newPage, stateChanged: false})
    case 'CHANGE_PAGE':
      toggleOnConfirmModal()
      return assign({}, state, {currentPage : action.page, stateChanged: false})
    case 'ADD_INCLUDED_DATE':
    case 'REMOVE_INCLUDED_DATE':
    case 'ADD_EXCLUDED_DATE':
    case 'REMOVE_EXCLUDED_DATE':
    case 'DELETE_PERIOD':
    case 'VALIDATE_PERIOD_FORM':
    case 'UPDATE_COMMENT':
    case 'UPDATE_COLOR':
    case 'UPDATE_DAY_TYPES':
    case 'UPDATE_CURRENT_MONTH_FROM_DAYTYPES':
      toggleOnConfirmModal('modal')
      return assign({}, state, {stateChanged: true})
    default:
      return state
  }
}

const toggleOnConfirmModal = (arg = '') =>{
  $('.confirm').each(function(){
    $(this).data('toggle','')
  })
}