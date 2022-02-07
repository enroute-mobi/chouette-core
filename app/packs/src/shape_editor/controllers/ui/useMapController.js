import { useEffect, useMemo } from 'react'
import { add, first, last, uniqueId } from 'lodash'

import Collection from 'ol/Collection'
import { Modify, Snap } from 'ol/interaction'
import { Vector as VectorLayer, Group as LayerGroup } from 'ol/layer'
import VectorSource from 'ol/source/Vector'

import Feature from 'ol/Feature'
import Point from 'ol/geom/Point'

import {
  getCoord,
  getCoords,
  length,
  lineSlice,
  lineString,
  nearestPointOnLine,
  toWgs84
} from '@turf/turf'

import store from '../../shape.store'
import eventEmitter, { events } from '../../shape.event-emitter'
import { getLineSections, lineId, mapFormat, simplifyGeometry } from '../../shape.helpers'
import { getGeometry, getLineLayer, getMap, getMapLine, getWaypointsLayer, getWaypointsCoords, getWaypoints } from '../../shape.selectors'
import { shapeEditorSyle as styles } from '../../../helpers/open_layers/styles'

export default function useMapController() {
  const SimplifiedLineBuilder = useMemo(() => {
    const getSectionsWithoutState = state => line => getLineSections(line || getGeometry(state), getWaypoints(state))

    return {
      call: state => {
        const getSections = getSectionsWithoutState(state)
        const simplifiedLine = simplifyGeometry(getSections(), getMap(state))

        const OlLine = mapFormat.readFeature(simplifiedLine)

        OlLine.setId(lineId)
        OlLine.setStyle(styles.lines.shape(getSections(simplifiedLine)))

        return OlLine
      }
    } 
  }, [])

  const updateLine = async () => {
    const state = await store.getStateAsync()
    const mapLine = getMapLine(state) // A OL Collection
    const lineItem = mapLine.item(0)

    const shouldSimplifyLine = state => getWaypoints(state).length > 25

    if (shouldSimplifyLine(state)) {
      const simplifiedLine = SimplifiedLineBuilder.call(state)

      lineItem.getGeometry().setCoordinates(
        simplifiedLine.getGeometry().getCoordinates()
      )

      lineItem.setStyle(simplifiedLine.getStyle())
    }

    mapLine.changed()
  }

  // Event Handlers
  const onMapInit = map => {
    const layers = map.getLayers()

    layers.item(1).set('static', true)

    const layerGroup = new LayerGroup({
      layers: [
        new VectorLayer({ source: new VectorSource(), line: true }),
        new VectorLayer({ source: new VectorSource(), waypoints: true })
      ],
      interactive: true
    })

    layers.push(layerGroup)

    store.initMap({ map })
  }

  const onReceiveShapeFeatures = async (_geometry, waypoints) => {
    let state = await store.getStateAsync()

    // Build features
    const line = new Collection([SimplifiedLineBuilder.call(state)])

    waypoints.forEach(w => {
      w.setId(uniqueId('waypoint_'))

      const waypointStyle = w.get('waypoint_type') === 'waypoint' ? 'shapeWaypoint' : 'shapeConstraint'
      w.setStyle(styles.points[waypointStyle])
    })

    getLineLayer(state).setSource(new VectorSource({ features: line }))
    getWaypointsLayer(state).setSource(new VectorSource({ features: waypoints }))

    // Add interactions
    const modify = new Modify({ features: line, type: 'modify' })
    const snap = new Snap({ features: new Collection([...line.getArray(), ...waypoints.getArray()]) })

    Array.of(modify, snap).forEach(i => getMap(state).addInteraction(i))

    store.setAttributes({ line, modify })
  }

  const onReceiveRouteFeatures = ([line, ...waypoints]) => {
    line.setStyle(styles.lines.route)

    const isEdgePoint = w => first(waypoints) == w || last(waypoints) == w

    waypoints.forEach(w => {
      const style = isEdgePoint(w) ? 'edge' : 'default'
      w.setStyle(styles.points.route[style])
    })
  }

  const handleAddPoint = async (startCoords, endCoords) => {
    const state = await store.getStateAsync()

    const waypointsCoords = getWaypointsCoords(state)
    const line = lineString(waypointsCoords)

    const linePoint = nearestPointOnLine(line, toWgs84(startCoords))
    const { index } = linePoint.properties

    const newLine = lineSlice(getCoords(line)[0], getCoord(linePoint), line)
    const other = lineSlice(getCoords(line)[0], waypointsCoords[index], line)

    const insertIndex = add(
      index,
      Boolean(length(newLine) > length(other))
    )

    const waypoint = new Feature({
      geometry: new Point(endCoords),
      id: uniqueId('waypoint_'),
      type: 'constraint',
    })

    waypoint.setStyle(styles.points.shapeConstraint)

    state.waypoints.insertAt(insertIndex, waypoint)
  }

  const handleWaypointZoom = async waypoint => {
    const { map } = await store.getStateAsync()

    map.getView().fit(waypoint.getGeometry(), { maxZoom: 17 })
  }

  const handleRemovePoint = async waypoint => {
    const { waypoints } = await store.getStateAsync()

    waypoints.remove(waypoint)
  }

  useEffect(() => {
    // Map
    eventEmitter.on(events.initMap, onMapInit)
    eventEmitter.on(events.mapZoom, updateLine)
    eventEmitter.on(events.mapMove, updateLine)

    // Feature Fetching
    eventEmitter.on(events.receivedRouteFeatures, onReceiveRouteFeatures)
    eventEmitter.on(events.receivedShapeFeatures, onReceiveShapeFeatures)
    
    // Actions
    eventEmitter.on(events.lineUpdated, updateLine)
    eventEmitter.on(events.waypointZoom, handleWaypointZoom)
    eventEmitter.on(events.waypointAdded, handleAddPoint)
    eventEmitter.on(events.waypointDeleted, handleRemovePoint)
  }, [])
}
