import { useEffect, useMemo } from 'react'
import { add, first, isEmpty, last, uniqueId } from 'lodash'

import Collection from 'ol/Collection'
import { Modify, Snap } from 'ol/interaction'
import { Vector as VectorLayer, Group as LayerGroup } from 'ol/layer'
import VectorSource from 'ol/source/Vector'
import { Circle, Fill, Stroke, Style } from 'ol/style'

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
import { getArrowStyles, getLineSections, lineId, mapFormat, simplifyGeometry } from '../../shape.helpers'
import { getGeometry, getLineLayer, getMap, getMapLine, getView, getWaypointsLayer, getWaypointsCoords, getWaypoints } from '../../shape.selectors'

const getStyles = () => ({
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
})

export default function useMapController() {
  const styles = getStyles()

  const SimplifiedLineBuilder = useMemo(() => {
    const getSectionsWithoutState = state => line => getLineSections(line || getGeometry(state), getWaypoints(state))

    return {
      call: state => {
        const getSections = getSectionsWithoutState(state)
        const simplifiedLine = simplifyGeometry(getSections(), getView(state))

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

    const newLine = SimplifiedLineBuilder.call(state)
    lineItem.getGeometry().setCoordinates(
      newLine.getGeometry().getCoordinates()
    )

    lineItem.setStyle(newLine.getStyle())

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
    const modify = new Modify({ features: line })
    const snap = new Snap({ features: new Collection([...line.getArray(), ...waypoints.getArray()]) })

    Array.of(modify, snap).forEach(i => getMap(state).addInteraction(i))

    store.setAttributes({ line, modify })

    eventEmitter.emit(events.initMapInteractions, waypoints, modify, snap)
  }

  const onReceiveRouteFeatures = ([line, ...waypoints]) => {
    line.setStyle(styles.lines.route)

    const isEdgePoint = w => first(waypoints) == w || last(waypoints) == w

    waypoints.forEach(w => {
      const style = isEdgePoint(w) ? 'edge' : 'default'
      w.setStyle(styles.points.route[style])
    })
  }

  const handleInteractionsInit = (waypoints, modify, _snap)  => {
    const map = modify.getMap()

    modify.on('modifystart', startEvent => {
      const { pixel, coordinate: startCoords } = startEvent.mapBrowserEvent
      const features = map.getFeaturesAtPixel(pixel, { layerFilter: l => l.get('waypoints') })

      const moveWaypoint = e => features.forEach(w => w.getGeometry().setCoordinates(e.coordinate))
      map.on('pointermove', moveWaypoint)

      modify.once('modifyend', async endEvent => {
        map.un('pointermove', moveWaypoint)

        // if there is not feature at pixel, we should add a waypoint
        if (isEmpty(features)) {
          const { coordinate: endCoords } = endEvent.mapBrowserEvent
          eventEmitter.emit(events.waypointAdded, startCoords, endCoords)
        } else {
          waypoints.changed()
        }
      })
    })
  }

  const handleAddPoint = async (startCoords, endCoords) => {
    const state = await store.getStateAsync()
    const styles = getStyles()

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
    eventEmitter.on(events.initMap, onMapInit)
    eventEmitter.on(events.initMapInteractions, handleInteractionsInit)
    eventEmitter.on(events.mapZoom, updateLine)

    eventEmitter.on(events.receivedRouteFeatures, onReceiveRouteFeatures)
    eventEmitter.on(events.receivedShapeFeatures, onReceiveShapeFeatures)
    
    eventEmitter.on(events.lineUpdated, updateLine)
    eventEmitter.on(events.waypointZoom, handleWaypointZoom)
    eventEmitter.on(events.waypointAdded, handleAddPoint)
    eventEmitter.on(events.waypointDeleted, handleRemovePoint)
  }, [])
}
