import EventEmitter from '../../src/helpers/EventEmitter'

export default new EventEmitter()

export const events = {
	initMap: 'map:init',
	initMapInteractions: 'map:init:interactions',
	mapZoom: 'map:zoom',
	waypointZoom: 'map:zoom:waypoint',
	receivedRouteFeatures: 'route:received-features',
	receivedShapeFeatures: 'shape:received-features',
	submitShapeRequest: 'shape:submit-request',
	lineUpdated: 'updated-line',
	waypointAdded: 'waypoints:added',
	waypointUpdated: 'waypoints:updated',
	waypointDeleteRequest: 'waypoints:delete-request',
	waypointDeleted: 'waypoints:deleted',
}
