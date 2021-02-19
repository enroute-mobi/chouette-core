import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { createSelectable } from 'react-selectable-fast'

class VehicleJourneyAtStop extends Component {
	constructor(props) {
		super(props)
		this.state = {
			hovered: false
		}
	}

	// Getters
	get hasDelta() {
		const { vjas: { delta } } = this.props

		return delta > 0
	}

	get selectionClasses() {
		const { isSelected, isInSelection } = this.props
		const out = []

		if (isSelected || isInSelection) {
			out.push('selected')	
		}

		return out.join(' ')
	}

	displayDelta() {
		const { vjas: { delta } } = this.props

		return delta > 99 ? '+' : delta
	}

	renderSelectionSize() {
		const { isSelectionBottomRight, selectionContentText } = this.props
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
			index,
			vjIndex,
			isDisabled,
			isEditable,
			cityNameChecker,
			toggleArrivals,
			hasUpdatePermission,
			selectableRef,
			isSelected,
			isSelecting,
			isInSelection
		} = this.props

		return (
			<div
				id={vjas.id}
				key={index}
				ref={selectableRef}
				className={`td text-center vjas-selectable ${this.selectionClasses}` }
				// onMouseDown={(e) => this.props.onSelectCell(vjIndex, index, 'down', e)}
				// onMouseUp={(e) => this.props.onSelectCell(vjIndex, index, 'up', e)}
				// onMouseEnter={(e) => this.props.onHoverCell(vjIndex, index, e)}
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
									onChange={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, 'hour', false, false) }}
									onMouseOut={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, 'hour', false, false, true) }}
									onBlur={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, 'hour', false, false, true) }}
									value={vjas.arrival_time['hour']}
								/>
								<span>:</span>
								<input
									type='number'
									className='form-control'
									disabled={!isEditable || isDisabled || !hasUpdatePermission}
									readOnly={!isEditable && !vjas.dummy}
									onChange={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, 'minute', false, false) }}
									onMouseOut={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, 'minute', false, false, true) }}
									onBlur={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, 'minute', false, false, true) }}
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
								onChange={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, 'hour', true, toggleArrivals) }}
								onMouseOut={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, 'hour', true, toggleArrivals, true) }}
								onBlur={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, 'hour', true, toggleArrivals, true) }}
								value={vjas.departure_time['hour']}
							/>
							<span>:</span>
							<input
								type='number'
								className='form-control'
								disabled={!isEditable || isDisabled || !hasUpdatePermission}
								readOnly={!isEditable && !vjas.dummy}
								onChange={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, "minute", true, toggleArrivals) }}
								onMouseOut={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, "minute", true, toggleArrivals, true) }}
								onBlur={(e) => { isEditable && this.props.onUpdateTime(e, index, vjIndex, "minute", true, toggleArrivals, true) }}
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
	vjIndex: PropTypes.number.isRequired,
	index: PropTypes.number.isRequired,
	vjas: PropTypes.object.isRequired,
	onSelectCell: PropTypes.func.isRequired,
	// onHoverCell: PropTypes.func.isRequired,
	isSelectionBottomRight: PropTypes.bool.isRequired,
	selectionContentText: PropTypes.string.isRequired,
	isEditable: PropTypes.bool.isRequired,
	isDisabled: PropTypes.bool.isRequired,
	vjas: PropTypes.object.isRequired,
	hasUpdatePermission: PropTypes.bool.isRequired,
	onUpdateTime: PropTypes.func.isRequired,
	cityNameChecker: PropTypes.func.isRequired,
	toggleArrivals: PropTypes.bool.isRequired
}
