export default function selection(state = {}, action) {
	switch(action.type) {
		case 'TOGGLE_SELECTION_MODE':			
			return {
				...state,
				active: !state.active
			}
		case 'UPDATE_SELECTED_ITEMS':
			return {
				...state,
				items: action.items
			}
		case 'UPDATE_SELECTION_DIMENSIONS':
			return {
				...state,
				width: action.width,
				height: action.height
			}
		case 'UPDATE_SELECTION_LOCKED':
			return {
				...state,
				locked: action.locked
			}

		case 'COPY_CLIPBOARD':
			return {
				...state,
				copyModal: {
					...state.copyModal,
					visible: true,
					mode: 'copy'
				}
			}
		case 'CLOSE_COPY_MODAL':
			return {
				...state,
				copyModal: {
					visible: false
				}
			}
		case 'COPY_MODAL_TO_PASTE_MODE':
			return {
				...state,
				copyModal: {
					...state.copyModal,
					visible: true,
					mode: 'paste'
				}
			}
		default:
			return state
	}
}

export const initialState = {
	active: false,
	isSelection: false,
	width: '',
	height: '',
	copyModal: { visible: false, mode: 'copy' },
	items: []
}
