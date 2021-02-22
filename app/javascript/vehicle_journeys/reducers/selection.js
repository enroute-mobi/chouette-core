import { flatten } from 'lodash'
import ClipboardHelper from '../helpers/ClipboardHelper'
import { initialState } from '../reducers'
import { computeDayOffSet } from '../helpers'

export default function selection(state = initialState, action) {
	const { selection, filters: { toggleArrivals } } = state
	const { copyModal } = selection

	switch(action.type) {
		case 'TOGGLE_SELECTION_MODE':	
			return {
				...state,
				selection: {
					active: !selection.active
				}
			}
		case 'UPDATE_SELECTED_ITEMS':
			return {
				...state,
				selection: {
					...selection,
					items: action.items
				},
			}
		case 'UPDATE_SELECTION_DIMENSIONS':
			return {
				...state,
				selection: {
					...selection,
					width: action.width,
					height: action.height
				}
			}
		case 'UPDATE_SELECTION_LOCKED':
			return {
				...state,
				selection: {
					...selection,
					locked: action.locked
				}
			}
		case 'COPY_CLIPBOARD':
		case 'COPY_MODAL_TO_COPY_MODE':
			ClipboardHelper.updateCopyContent(selection.items, selection.width)

			return {
				...state,
				selection: {
					...selection,
					copyModal: {
						visible: true,
						mode: 'copy',
						content: {
							copy: ClipboardHelper.content.copy.serialize(toggleArrivals)
						}
					}
				}
			}
		case 'CLOSE_COPY_MODAL':
			return {
				...state,
				selection: {
					...selection,
					copyModal: {
						...copyModal,
						visible: false
					}
				}
			}
		case 'COPY_MODAL_TO_PASTE_MODE':
		case 'PASTE_CLIPBOARD':
			ClipboardHelper.updatePasteContent('')	
			return {
				...state,
				selection: {
					...selection,
					copyModal: {
						visible: true,
						mode: 'paste',
						pasteOnly: action.type == 'PASTE_CLIPBOARD',
						content: {
							...copyModal.content,
							paste: ''
						}
					}
				}
			}
		case 'UPDATE_CONTENT_TO_PASTE':
			ClipboardHelper.updatePasteContent(action.content)
			ClipboardHelper.validatePasteContent(toggleArrivals)

			return {
				...state,
				selection: {
					...selection,
					copyModal: {
						...copyModal,
						error: ClipboardHelper.error,
						content: {
							...copyModal.content,
							paste: ClipboardHelper.content.paste.serialize(toggleArrivals)
						}
					}
				}
			}
		case 'PASTE_CONTENT':
			if (ClipboardHelper.error) return state

			const pasteContent = ClipboardHelper.content.paste.deserialize(toggleArrivals)
			const stops = flatten(pasteContent)

			let prevStop

			const vehicleJourneys = state.vehicleJourneys.map((vj, i) => {
				const newStops = vj.vehicle_journey_at_stops.map((vjas, j) => {
					const stopParams = stops.find(stop => stop.vjIndex == i && stop.index == j) || vjas
					const dayOffSets = computeDayOffSet(prevStop, stopParams)

					prevStop = vjas

					return {
						...vjas,
						...dayOffSets,
						departure_time: stopParams.departure_time,
						arrival_time: stopParams.arrival_time,
					}
				})


				return {
					...vj,
					vehicle_journey_at_stops: newStops
				}
			})
	
			return {
				...state,
				vehicleJourneys,
				selection: {
					...selection,
					copyModal: {
						visible: false
					}
				}
			}
		default:
			return state
		}
}
