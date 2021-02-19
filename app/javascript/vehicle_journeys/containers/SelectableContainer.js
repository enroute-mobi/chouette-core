import actions from '../actions'
import { connect } from 'react-redux'
import SelectableContainer from '../components/SelectableContainer'

const mapStateToProps = (state) => ({
	selectionMode: state.selection.active,
	toggleArrivals: state.filters.toggleArrivals
})

const mapDispatchToProps = (dispatch) => ({
	updateSelectedItems: items => {
		dispatch(actions.updateSelectedItems(items))
	},
	updateSelectionDimensions: (width, height) => {
		dispatch(actions.updateSelectionDimensions(width, height))
	},
	updateSelectionLocked: bool => {
		dispatch(actions.updateSelectionLocked(bool))
	}
})

export default connect(mapStateToProps, mapDispatchToProps)(SelectableContainer)
