export const INIT_MAP = 'INIT_MAP'
export const RECEIVE_PERMISSIONS = 'RECEIVE_PERMISSIONS'
export const RECEIVE_ROUTE_FEATURES = 'RECEIVE_ROUTE_FEATURES'
export const RECEIVE_SHAPE_FEATURES = 'RECEIVE_SHAPE_FEATURES'
export const SET_ATTRIBUTES = 'SET_ATTRIBUTES'
export const UPDATE_GEOMETRY = 'UPDATE_GEOMETRY'
export const UPDATE_NAME = 'UPDATE_NAME'
export const UPDATE_WAYPOINTS = 'UPDATE_WAYPOINTS'

export const actions = {
	initMap: payload => ({ type: INIT_MAP, payload }),
	receivePermissions: payload => ({ type: RECEIVE_PERMISSIONS, payload }),
	receivedRouteFeatures: payload => ({ type: RECEIVE_ROUTE_FEATURES, payload }),
	receivedShapeFeatures: payload => ({ type: RECEIVE_SHAPE_FEATURES, payload }),
	setAttributes: payload => ({ type: SET_ATTRIBUTES, payload }),
	updateGeometry: payload => ({ type: UPDATE_GEOMETRY, payload }),
	updateName: payload => ({ type: UPDATE_NAME, payload }),
	updateWaypoints: payload => ({ type: UPDATE_WAYPOINTS, payload }),
}
