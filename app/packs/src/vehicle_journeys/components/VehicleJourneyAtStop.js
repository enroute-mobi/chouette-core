import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { partial } from 'lodash'
import { createSelectable } from 'react-selectable-fast'
import autoBind from 'react-autobind'

class VehicleJourneyAtStop extends Component {
	constructor(props) {
		super(props)
		
		autoBind(this)
	}

	// Getters
	get hasDelta() {
		const { vjas: { delta } } = this.props

		return delta > 0
	}

	get tdClasses() {
		const {
			isSelecting,
			isSelected,
			isInSelection
		} = this.props
		const out = ['td', 'text-center']

		out.push('selectable')

		if (isSelecting || isSelected || isInSelection) {
			out.push('selected')	
		}

		return out.join(' ')
	}

	displayDelta() {
		const { vjas: { delta } } = this.props

		return delta > 99 ? '+' : delta
	}

	onUpdateTime(subIndex, index, e, timeUnit, isDeparture, isArrivalsToggled, enforceConsistency = false) {
		const { value } = e.target
		this.props.onUpdateTime(value, subIndex, index, timeUnit, isDeparture, isArrivalsToggled, enforceConsistency)
	}

	renderSelectionSize() {

		const { isSelectionBottomRight, selectionContentText, selectionMode } = this.props

		if (!selectionMode) return false

		return isSelectionBottomRight && (
			<div className='selection-size-helper'>
				{selectionContentText}
			</div>
		)
	}

	renderDelta() {
		return (
			<div className={(this.hasDelta ? '' : 'hidden')}>
				{this.hasDelta &&
					<span className='sb sb-chrono sb-lg text-warning' data-textinside={this.displayDelta()}></span>
				}
			</div>
		)
	}

	render() {
		const {
			vjas,
			x,
			y,
			isDisabled,
			isEditable,
			cityNameChecker,
			toggleArrivals,
			hasUpdatePermission,
			selectableRef,
		} = this.props

		const onUpdateTime = partial(this.onUpdateTime, y, x)

		return (
			<div
				id={vjas.id}
				key={y}
				ref={selectableRef}
				className={this.tdClasses}
			>
				{this.renderSelectionSize()}
				<div className={'cellwrap' + (cityNameChecker(vjas) ? ' headlined' : '')}>
					{toggleArrivals &&
						<div data-headline={I18n.t("vehicle_journeys.form.arrival_at")}>
							<span className={((isDisabled || !hasUpdatePermission) ? 'disabled ' : '') + 'input-group time'}>
								<input
									type='number'
									className='form-control'
									disabled={!isEditable || isDisabled || !hasUpdatePermission}
									readOnly={!isEditable && !vjas.dummy}
									onChange={e => { isEditable && onUpdateTime(e, 'hour', false, false) }}
									onMouseOut={e => { isEditable && onUpdateTime(e, 'hour', false, false, true) }}
									onBlur={e => { isEditable && onUpdateTime(e, 'hour', false, false, true) }}
									value={vjas.arrival_time['hour']}
								/>
								<span>:</span>
								<input
									type='number'
									className='form-control'
									disabled={!isEditable || isDisabled || !hasUpdatePermission}
									readOnly={!isEditable && !vjas.dummy}
									onChange={e => { isEditable && onUpdateTime(e, 'minute', false, false) }}
									onMouseOut={e => { isEditable && onUpdateTime(e, 'minute', false, false, true) }}
									onBlur={e => { isEditable && onUpdateTime(e, 'minute', false, false, true) }}
									value={vjas.arrival_time['minute']}
								/>
							</span>
						</div>
					}
					{this.renderDelta()}
					<div data-headline={I18n.t("vehicle_journeys.form.departure_at")}>
						<span className={((isDisabled || !hasUpdatePermission) ? 'disabled ' : '') + 'input-group time'}>
							<input
								type='number'
								className='form-control'
								disabled={!isEditable || isDisabled || !hasUpdatePermission}
								readOnly={!isEditable && !vjas.dummy}
								onChange={e => { isEditable && onUpdateTime(e, 'hour', true, toggleArrivals) }}
								onMouseOut={e => { isEditable && onUpdateTime(e, 'hour', true, toggleArrivals, true) }}
								onBlur={e => { isEditable && onUpdateTime(e, 'hour', true, toggleArrivals, true) }}
								value={vjas.departure_time['hour']}
							/>
							<span>:</span>
							<input
								type='number'
								className='form-control'
								disabled={!isEditable || isDisabled || !hasUpdatePermission}
								readOnly={!isEditable && !vjas.dummy}
								onChange={e => { isEditable && onUpdateTime(e, 'minute', true, toggleArrivals) }}
								onMouseOut={e => { isEditable && onUpdateTime(e, 'minute', true, toggleArrivals, true) }}
								onBlur={e => { isEditable && onUpdateTime(e, 'minute', true, toggleArrivals, true) }}
								value={vjas.departure_time['minute']}
							/>
						</span>
					</div>
				</div>
			</div>
		)
	}
}

export default createSelectable(VehicleJourneyAtStop)

VehicleJourneyAtStop.propTypes = {
	x: PropTypes.number.isRequired,
	y: PropTypes.number.isRequired,
	vjas: PropTypes.object.isRequired,
	isSelectionBottomRight: PropTypes.bool.isRequired,
	selectionContentText: PropTypes.string.isRequired,
	isEditable: PropTypes.bool.isRequired,
	isDisabled: PropTypes.bool.isRequired,
	vjas: PropTypes.object.isRequired,
	hasUpdatePermission: PropTypes.bool.isRequired,
	onUpdateTime: PropTypes.func.isRequired,
	cityNameChecker: PropTypes.func.isRequired,
	toggleArrivals: PropTypes.bool.isRequired,
	selectionMode: PropTypes.bool.isRequired,
	isInSelection: PropTypes.bool.isRequired,
}
