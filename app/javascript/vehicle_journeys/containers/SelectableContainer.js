import actions from '../actions'
import { connect } from 'react-redux'
import { flatten } from 'lodash'
import SelectableContainer from '../components/SelectableContainer'

const mapStateToProps = ({ selection, filters, vehicleJourneys }) => ({
	selectionMode: selection.active,
	selectedItems: selection.items || [],
	toggleArrivals: filters.toggleArrivals,
	vehicleJourneysAtStops: flatten(vehicleJourneys.map((vj, x) =>
		vj.vehicle_journey_at_stops.map((vjas, y) => ({
			...vjas, x, y
		}))
	))
})

const mapDispatchToProps = (dispatch) => ({
	updateSelectedItems: items => {
		dispatch(actions.updateSelectedItems(items))
	},
	clearSelectedItems: () => dispatch(actions.clearSelectedItems()),
	updateSelectionDimensions: (width, height) => {
		dispatch(actions.updateSelectionDimensions(width, height))
	},
	updateSelectionLocked: bool => {
		dispatch(actions.updateSelectionLocked(bool))
	}
})

export default connect(mapStateToProps, mapDispatchToProps)(SelectableContainer)
