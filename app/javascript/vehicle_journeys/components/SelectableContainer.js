import React, { useEffect, useState } from 'react'
import PropTypes from 'prop-types'
import { SelectableGroup } from 'react-selectable-fast'
import { inRange, isEmpty, map, max, min, reduce } from 'lodash'
import { useDebounce } from '../../helpers/hooks'

const SelectableContainer = props => {
	const {
		children,
		clearSelectedItems,
		selectionMode,
		selectedItems,
		updateSelectedItems,
		updateSelectionDimensions,
		updateSelectionLocked,
		vehicleJourneysAtStops
	} = props

	const [bounds, setBounds] = useState(null)
	const [locked, setLocked] = useState(false)

	const handleClear = () => {
		setLocked(false)
		setBounds(null)
	}

	const handleNewSelection = done => items => {
		const itemCollection = [...selectedItems, ...map(items, 'props')]

		setLocked(done)

		setBounds(() =>
			reduce(itemCollection, (result, item) => {
				const { minX, maxX, minY, maxY } = result
				const { y, x } = item

				return {
					minX: min([minX, x]),
					maxX: max([maxX, x]),
					minY: min([minY, y]),
					maxY: max([maxY, y])
				}
			}, {})
		)
	}

	const handleSelecting = useDebounce(handleNewSelection(false), 300)

	const handleSelectFinish = items => {
		const hasItems = !isEmpty(items)
		setTimeout(() => {
			hasItems && handleNewSelection(true)(items)
		}, 301)
	}

	useEffect(() => {
		if (bounds) {
			const width = (bounds.maxX - bounds.minX) + 1
			const height = (bounds.maxY - bounds.minY) + 1

			const newSelectedItems = vehicleJourneysAtStops.filter(vjas =>
				inRange(vjas.x, bounds.minX, bounds.maxX + 1) &&
				inRange(vjas.y, bounds.minY, bounds.maxY + 1)
			)

			updateSelectedItems(newSelectedItems)
			updateSelectionDimensions(width, height)
			locked && updateSelectionLocked(true)
		} else {
			clearSelectedItems()
		}
	}, [bounds])

	if (!selectionMode)
		return children

	return (
		<SelectableGroup
			className="selectable-container"
			disabled={!selectionMode}
			duringSelection={handleSelecting}
			onSelectionFinish={handleSelectFinish}
			onSelectionClear={handleClear}
			scrollContainer='.scrollable-container'
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
	vehicleJourneysAtStops: PropTypes.array.isRequired
}
