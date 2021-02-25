import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { SelectableGroup } from 'react-selectable-fast'
import { isEmpty, sortBy } from 'lodash'
import autoBind from 'react-autobind'

export default class SelectableContainer extends Component {
	constructor(props) {
		super(props)
		autoBind(this)
	}

	handleSelecting(items) {
		const initialState = { width: new Set(), height: new Set(), selectedItems: [] } // Use of Set to eliminate duplicate values

		const { width, height, selectedItems } = items.reduce((result, item) => {
			const {
				props: {
					vjas: { id, arrival_time, departure_time, dummy, delta },
					index,
					vjIndex
				}
			} = item
			const selectedItem = { id, index, vjIndex, arrival_time, departure_time, dummy, delta }
			return {
				width: result.width.add(vjIndex),
				height: result.height.add(index),
				selectedItems: sortBy([...result.selectedItems, selectedItem], ['index', 'vjIndex'])
			}
		}, initialState)

		this.props.updateSelectedItems(selectedItems)
		this.props.updateSelectionDimensions(width.size, height.size)
	}

	handleSelectFinish(items) {
		const { updateSelectionLocked, toggleArrivals } = this.props
		const hasItems = !isEmpty(items)

		updateSelectionLocked(hasItems)
	}

	render() {
		const { selectionMode } = this.props
		return (
			<SelectableGroup
				className="selectable-container"
				resetOnStart
				disabled={!selectionMode}
				duringSelection={this.handleSelecting}
				onSelectionFinish={this.handleSelectFinish}
			>
				{this.props.children}
			</SelectableGroup>
		)
	}
}

SelectableContainer.propTypes = {
	selectionMode: PropTypes.bool.isRequired,
	toggleArrivals: PropTypes.bool.isRequired,
	updateSelectedItems: PropTypes.func.isRequired,
	updateSelectionDimensions: PropTypes.func.isRequired,
	updateSelectionLocked: PropTypes.func.isRequired,
}
