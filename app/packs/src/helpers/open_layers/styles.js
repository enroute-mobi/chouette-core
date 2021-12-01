import { Circle, Fill, Icon, RegularShape, Stroke, Style } from 'ol/style'
import Point from 'ol/geom/Point'

import { flow, partialRight, sortBy } from 'lodash'

import {
	along,
	bearing,
	degreesToRadians,
	getCoord,
	getCoords,
	length,
	pointToLineDistance,
	toMercator,
} from '@turf/turf'

import { featureMap, segmentMap } from '../../shape_editor/shape.helpers'

import BluePin from 'images/icons/map_pin_blue.png'
import OrangePin from 'images/icons/map_pin_orange.png'

const markers = {
	blue: BluePin,
	orange: OrangePin
}

export const connectionLinkStyle = color =>
	new Style({
		image: new Icon({
			anchor: [0.5, 1],
			anchorXUnits: 'fraction',
			anchorYUnits: 'fraction',
			src: markers[color]
		})
	})

// Shape Editor
/**
 * Compute Line Arrow Styles that display the line direction
 * @param {GeoJSON} sectionCollection A Feature Collection of LineString
 * @return {array} A array of style objects
 */
const getArrowStyles = flow(
	partialRight(
		featureMap,
		section => {
			const midPointCoords = flow(line => along(line, length(line) / 2), getCoord)(section)

			const segments = segmentMap(
				section,
				({ properties, ...segment }) => ({
					...segment,
					properties: { ...properties, distance: pointToLineDistance(midPointCoords, segment) }
				})
			)

			const midSegment = sortBy(segments, segment => segment.properties.distance)[0]
			
			const getArrowRotation = flow(getCoords, coords => bearing(...coords), degreesToRadians)

			return new Style({
				geometry: new Point(toMercator(midPointCoords)),
				image: new RegularShape({
					fill: new Fill({ color: 'red' }),
					points: 3,
					radius: 7,
					rotation: getArrowRotation(midSegment)
				})
			})
		}
	)
)

export const shapeEditorSyle = {
	points: {
		shapeWaypoint: new Style({
			image: new Circle({
				radius: 8,
				stroke: new Stroke({ color: 'white', width: 2 }),
				fill: new Fill({ color: 'red' })
			})
		}),
		shapeConstraint: new Style({
			image: new Circle({
				radius: 8,
				stroke: new Stroke({ color: 'red', width: 2 }),
				fill: new Fill({ color: 'white' })
			})
		}),
		route: {
			default: new Style({
				image: new Circle({
					radius: 5,
					stroke: new Stroke({ color: '#007fbb', width: 0.75 }),
					fill: new Fill({ color: '#ffffff' })
				})
			}),
			edge: new Style({
				image: new Circle({
					radius: 5,
					stroke: new Stroke({ color: '#007fbb', width: 0.75 }),
					fill: new Fill({ color: '#007fbb' })
				})
			})
		}
	},
	lines: {
		route: new Style({
			stroke: new Stroke({
				color: '#007fbb',
				width: 1.5,
			})
		}),
		shape: sections => [
			new Style({
				stroke: new Stroke({
					color: 'red',
					width: 2
				})
			}),
			...getArrowStyles(sections)
		]
	}
}

export const setLineStyle = features => {
	const styles = lineStyle(features)
	features.forEach((f, i) => {
		f.setStyle(styles[i])
	})
}

export const lineStyle = ([_line, ...waypoints]) => {
	const styles = [
		new Style({
			stroke: new Stroke({
				color: '#007fbb',
				width: 2
			})
		}),
		new Style({
			image: new Circle({
				radius: 5,
				stroke: new Stroke({
					color: '#007fbb',
					width: 0
				}),
				fill: new Fill({
					color: '#007fbb',
					width: 0
				})
			})
		}),
		new Style({
			image: new Circle({
				radius: 5,
				stroke: new Stroke({
					color: '#007fbb',
					width: 0
				}),
				fill: new Fill({
					color: '#007fbb',
					width: 0
				})
			})
		})
	]

	return [
		...styles.slice(0, 2),
		...waypoints.reduce((list, _waypoint, i) => {

			if (i == 0 || i == (waypoints.length - 1)) return list

			return [
				...list,
				new Style({
					image: new Circle({
						radius: 4,
						stroke: new Stroke({
							color: '#007fbb',
							width: 0
						}),
						fill: new Fill({
							color: '#ffffff',
							width: 0
						})
					})
				})
			]
		}, []),
		...styles.slice(2)
	]
}

export const setConnectionLinkStyle = connectionLinks => {
	connectionLinks.forEach(connectionLink => {
		connectionLink.setStyle(
			connectionLinkStyle(connectionLink.get('marker'))
		)
	})
}
