import assign from 'lodash/assign'
import actions from '../actions'

let newModalProps = {}
let emptyDate = {
  day: '01',
  month: '01',
  year: String(new Date().getFullYear())
}
let period_start = '', period_end = ''

export default function modal(state = {}, action) {
  switch (action.type) {
    case 'OPEN_CONFIRM_MODAL':
      $('#ConfirmModal').modal('show')
      return assign({}, state, {
        type: 'confirm',
        confirmModal: {
          callback: action.callback,
        }
      })
    case 'OPEN_ERROR_MODAL':
      $('#ErrorModal').modal('show')
      newModalProps = assign({}, state.modalProps, {error: action.error})
      return assign({}, state, {type: 'error'}, {modalProps: newModalProps})
    case 'RESET_MODAL_ERRORS':
      newModalProps = assign({}, state.modalProps, {error: ''})
      return assign({}, state, {type: ''}, {modalProps: newModalProps})
    case 'CLOSE_PERIOD_FORM':
      newModalProps = assign({}, state.modalProps, {active: false, error: ""})
      return assign({}, state, {modalProps: newModalProps})
    case 'OPEN_EDIT_PERIOD_FORM':
      period_start = action.period.period_start.split('-')
      period_end = action.period.period_end.split('-')
      newModalProps = JSON.parse(JSON.stringify(state.modalProps))

      newModalProps.begin.year = period_start[0]
      newModalProps.begin.month = period_start[1]
      newModalProps.begin.day = period_start[2]

      newModalProps.end.year = period_end[0]
      newModalProps.end.month = period_end[1]
      newModalProps.end.day = period_end[2]

      newModalProps.active = true
      newModalProps.index = action.index
      newModalProps.error = ''
      return assign({}, state, {modalProps: newModalProps})
    case 'OPEN_ADD_PERIOD_FORM':
      newModalProps = assign({}, state.modalProps, {active: true, begin: emptyDate, end: emptyDate, index: false, error: ''})
      return assign({}, state, {modalProps: newModalProps})
    case 'UPDATE_PERIOD_FORM':
      newModalProps = JSON.parse(JSON.stringify(state.modalProps))
      newModalProps[action.group][action.selectType] = action.val
      return assign({}, state, {modalProps: newModalProps})
    case 'VALIDATE_PERIOD_FORM':
      newModalProps = JSON.parse(JSON.stringify(state.modalProps))
      newModalProps.error = action.error
      newModalProps.active = (newModalProps.error == '') ? false : true
      return assign({}, state, {modalProps: newModalProps})
    default:
      return state
  }
}