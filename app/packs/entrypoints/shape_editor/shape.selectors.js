import { flow, get } from 'lodash'

import { coordAll, getCoord, getCoords } from '@turf/turf'

import { featureMap, getLayer, getSource, mapFormat } from './shape.helpers'

export const getMapLine = ({ line }) => line
export const getLine = ({ line }) => writeFeatureObject(line.item(0))
export const getGeometry = ({ geometry }) => geometry
export const getWaypoints = ({ waypoints }) => mapFormat.writeFeaturesObject(waypoints.getArray())

export const getLineCoords = flow(getGeometry, getCoords)
export const getWaypointsCoords = flow(getWaypoints, coordAll)

export const getMap = ({ map }) => map
export const getView = flow(getMap, map => map.getView())
export const getCurrentZoom = flow(getView, view => view.getZoom())

export const getStaticlayer = flow(getMap, getLayer('static'))
export const getInteractiveLayerGroup = flow(getMap, getLayer('interactive'))
export const getLineLayer = flow(getInteractiveLayerGroup, getLayer('line'))
export const getWaypointsLayer = flow(getInteractiveLayerGroup, getLayer('waypoints'))

export const getLineSource = flow(getLineLayer, getSource)
export const getWaypointsSource = flow(getWaypointsLayer, getSource)

export const getSubmitPayload = state => ({
	shape: {
		name: state.name,
		coordinates: getLineCoords(state),
		waypoints: featureMap(
			getWaypoints(state),
			(w, position) => ({
				name: get(w, ['properties', 'name'], ''),
				position,
				waypoint_type: get(w, ['properties', 'type'], 'waypoint'),
				coordinates: getCoord(w)
			})
		)
	}
})

