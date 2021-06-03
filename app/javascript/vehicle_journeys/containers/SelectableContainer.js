import actions from '../actions'
import { connect } from 'react-redux'
import { flatten, sortBy } from 'lodash'
import SelectableContainer from '../components/SelectableContainer'

const sortedVjas = vehicleJourneys => {
	const vjasMapper = x => (vjas, y) => ({ ...vjas, x, y })
	const vjMapper = (vj, x) => vj.vehicle_journey_at_stops.map(vjasMapper(x))

	const vjas = flatten(vehicleJourneys.map(vjMapper))

	return sortBy(vjas, ['y', 'x'])
}

const mapStateToProps = ({ selection, filters, vehicleJourneys }) => ({
	selectionMode: selection.active,
	selectedItems: selection.items || [],
	toggleArrivals: filters.toggleArrivals,
	vehicleJourneysAtStops: sortedVjas(vehicleJourneys)
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
