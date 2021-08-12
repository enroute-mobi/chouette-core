import _ from 'lodash'

let journeyPattern, newModalProps

export default function modal(state = {}, action) {
  switch (action.type) {
    case 'OPEN_CONFIRM_MODAL':
      $('#ConfirmModal').modal('show')
      return _.assign({}, state, {
        type: 'confirm',
        confirmModal: {
          callback: action.callback,
        }
      })
    case 'EDIT_JOURNEYPATTERN_MODAL':
      return {
        type: 'edit',
        modalProps: {
          index: action.index,
          journeyPattern: action.journeyPattern
        },
        confirmModal: {}
      }
    case 'SELECT_SHAPE_EDIT_MODAL':
      journeyPattern =  _.assign({}, state.modalProps.journeyPattern, {shape: action.selectedItem})
      newModalProps = _.assign({}, state.modalProps, {journeyPattern})
      return _.assign({}, state, {modalProps: newModalProps})
    case 'UNSELECT_SHAPE_EDIT_MODAL':
      journeyPattern =  _.assign({}, state.modalProps.journeyPattern, {shape: undefined})
      newModalProps = _.assign({}, state.modalProps, {journeyPattern})
      return _.assign({}, state, {modalProps: newModalProps})
    case 'CREATE_JOURNEYPATTERN_MODAL':
      return {
        type: 'create',
        modalProps: {},
        confirmModal: {}
      }
    case 'DELETE_JOURNEYPATTERN':
      return _.assign({}, state, { type: '' })
    case 'SAVE_MODAL':
      return _.assign({}, state, { type: '' })
    case 'CLOSE_MODAL':
      return {
        type: '',
        modalProps: {},
        confirmModal: {}
      }
    default:
      return state
  }
}
