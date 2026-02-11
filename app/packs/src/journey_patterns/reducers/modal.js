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
    case 'ADD_CODE':
      if (state.modalProps.journeyPattern && (state.modalProps.index === action.index || (state.modalProps.index === undefined && action.index === null))) {
        const newCodes = [...(state.modalProps.journeyPattern.code_values || []), action.code]
        journeyPattern = _.assign({}, state.modalProps.journeyPattern, {code_values: newCodes})
        newModalProps = _.assign({}, state.modalProps, {journeyPattern})
        return _.assign({}, state, {modalProps: newModalProps})
      }
      return state
    case 'UPDATE_CODE':
      if (state.modalProps.journeyPattern && (state.modalProps.index === action.index || (state.modalProps.index === undefined && action.index === null))) {
        const updatedCodes = (state.modalProps.journeyPattern.code_values || []).map((code, index) => {
          if (index === action.code.index) {
            return _.assign({}, code, {
              code_space_id: action.code.code_space_id,
              value: action.code.value
            })
          }
          return code
        })
        journeyPattern = _.assign({}, state.modalProps.journeyPattern, {code_values: updatedCodes})
        newModalProps = _.assign({}, state.modalProps, {journeyPattern})
        return _.assign({}, state, {modalProps: newModalProps})
      }
      return state
    case 'DELETE_CODE':
      if (state.modalProps.journeyPattern && (state.modalProps.index === action.index || (state.modalProps.index === undefined && action.index === null))) {
        const codesAfterDelete = [...(state.modalProps.journeyPattern.code_values || [])]
        codesAfterDelete.splice(action.index, 1)
        journeyPattern = _.assign({}, state.modalProps.journeyPattern, {code_values: codesAfterDelete})
        newModalProps = _.assign({}, state.modalProps, {journeyPattern})
        return _.assign({}, state, {modalProps: newModalProps})
      }
      return state
    case 'CREATE_JOURNEYPATTERN_MODAL':
      return {
        type: 'create',
        modalProps: {
          journeyPattern: {
            name: '',
            published_name: '',
            registration_number: '',
            booking_arrangement_id: '',
            code_values: []
          }
        },
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
