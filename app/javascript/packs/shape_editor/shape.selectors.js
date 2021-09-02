import { flow, map } from 'lodash'

import { coordAll, getCoords } from '@turf/turf'

import { getFeatureCoordinates, getLayer, getSource, lineId, mapFormat } from './shape.helpers'

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
		coordinates: getLineCoords(stae),
		waypoints: map(getWaypoints(state), (w, position) => ({
			name: w.get('name'),
			position,
			waypoint_type: w.get('type'),
			coordinates: getFeatureCoordinates(w)
		}))
	}
})

