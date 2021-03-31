import React from 'react'
import PropTypes from 'prop-types'
import { SelectableGroup } from 'react-selectable-fast'
import { isEmpty, sortBy } from 'lodash'


const SelectableContainer = props => {
	const {
		children,
		clearSelectedItems,
		selectionMode,
		updateSelectedItems,
		updateSelectionDimensions,
		updateSelectionLocked
	} = props

	const handleSelecting = items => {
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

		updateSelectedItems(selectedItems)
		updateSelectionDimensions(width.size, height.size)
	}

	const handleSelectFinish = items => {
		const hasItems = !isEmpty(items)
		updateSelectionLocked(hasItems)
	}

	if (!selectionMode)
		return children

	return (
		<SelectableGroup
			className="selectable-container"
			resetOnStart
			disabled={!selectionMode}
			duringSelection={handleSelecting}
			onSelectionFinish={handleSelectFinish}
			onSelectionClear={clearSelectedItems}
			ignoreList={['.not-selectable']}
			scrollContainer='.scrollable-container'
			selectOnClick={false}
		>
			{children}
		</SelectableGroup>
	)
}

export default SelectableContainer

SelectableContainer.propTypes = {
	selectionMode: PropTypes.bool.isRequired,
	toggleArrivals: PropTypes.bool.isRequired,
	updateSelectedItems: PropTypes.func.isRequired,
	updateSelectionDimensions: PropTypes.func.isRequired,
	updateSelectionLocked: PropTypes.func.isRequired,
}
