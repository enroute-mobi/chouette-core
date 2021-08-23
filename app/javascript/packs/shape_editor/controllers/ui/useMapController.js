import { useEffect } from 'react'
import { add, debounce, first, isEmpty, last, uniqueId } from 'lodash'

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
import eventEmitter from '../../shape.event-emitter'
import { getArrowStyles, getLineLayer, getWaypointsLayer, getWaypointsCoords, lineId } from '../../shape.helpers'

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
    shape: _feature => {
      const { map } = store.getStateSync()

      return [
        new Style({
          stroke: new Stroke({
            color: 'red',
            width: 2
          })
        }),
        ...getArrowStyles(map)
      ]
    }
  }
})

export default function useMapController() {
  const styles = getStyles()

  // Event Handlers
  const onMapInit = async map => {
    const layers = map.getLayers()
    window.map = map

    layers.item(1).set('static', true)

    const layerGroup = new LayerGroup({ layers: [
      new VectorLayer({ source: new VectorSource(), line: true }),
      new VectorLayer({ source: new VectorSource(), waypoints: true })
    ], interactive: true })

    layers.push(layerGroup)

    store.setAttributes({ map })
  }

  const onReceiveShapeFeatures = async (line, waypoints) => {
    const { map } = await store.getStateAsync()

    const lineLayer = getLineLayer(map)
    const waypointsLayer = getWaypointsLayer(map)

    line.setId(lineId)

    const shapeLineStyleFunc = debounce(styles.lines.shape, 100, { leading: true })
    line.setStyle(shapeLineStyleFunc)

    waypoints.forEach(w => {
      w.setId(uniqueId('waypoint_'))

      const waypointStyle = w.get('type') == 'waypoint' ? 'shapeWaypoint' : 'shapeConstraint'
      w.setStyle(styles.points[waypointStyle])
    })

    const modify = new Modify({ features: new Collection([line]) })

    eventEmitter.emit('map:init-modify', modify)
    
    const snap = new Snap({ features: new Collection([ line, ...waypoints.getArray()]) })
    const interactions = [modify, snap]

    lineLayer.setSource(new VectorSource({ features: new Collection([line]) }))
    waypointsLayer.setSource(new VectorSource({ features: waypoints }))

    store.setAttributes({ modify })

    interactions.forEach(i => map.addInteraction(i))
  }

  const onReceiveRouteFeatures = ([line, ...waypoints]) => {
    line.setStyle(styles.lines.route)

    const isEdgePoint = w => first(waypoints) == w || last(waypoints) == w

    waypoints.forEach(w => {
      const style = isEdgePoint(w) ? 'edge' : 'default'
      w.setStyle(styles.points.route[style])
    })
  }

  const onInitModify = async modify  => {
    modify.on('modifystart', startEvent => {
      const { pixel, coordinate: startCoords } = startEvent.mapBrowserEvent
      const features = map.getFeaturesAtPixel(pixel, { layerFilter: l => l.get('waypoints') })

      const moveWaypoint = e => features.forEach(w => w.getGeometry().setCoordinates(e.coordinate))
      map.on('pointermove', moveWaypoint)

      modify.once('modifyend', async endEvent => {
        const { map, waypoints } = await store.getStateAsync()

        map.un('pointermove', moveWaypoint)

        // if there is not feature at pixel, we should add a waypoint
        if (isEmpty(features)) {
          const { coordinate: endCoords } = endEvent.mapBrowserEvent
          eventEmitter.emit('map:add-waypoint', map, waypoints, startCoords, endCoords)
        } else {
          waypoints.changed()
        }

        store.setAttributes({ waypoints })
      })
    })
  }

  const handleAddPoint = async (map, waypoints, startCoords, endCoords) => {
    const styles = getStyles()

    const waypointsCoords = getWaypointsCoords(map)
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
      type: 'constraint',
    })

    waypoint.setStyle(styles.points.shapeConstraint)

    waypoints.insertAt(insertIndex, waypoint)
  }

  const handleWaypointZoom = async waypoint => {
    const { map } = await store.getStateAsync()

    map.getView().fit(waypoint.getGeometry(), { maxZoom: 17 })
  }

  const handleRemovePoint = async waypoint => {
    const { waypoints } = await store.getStateAsync()

    waypoints.remove(waypoint)
    store.setAttributes({ waypoints })
  }

  useEffect(() => {
    eventEmitter.on('map:init', onMapInit)
    eventEmitter.on('route:receive-features', onReceiveRouteFeatures)
    eventEmitter.on('shape:receive-features', onReceiveShapeFeatures)
    eventEmitter.on('map:init-modify', onInitModify)
    eventEmitter.on('map:zoom-to-waypoint', handleWaypointZoom)
    eventEmitter.on('map:add-waypoint', handleAddPoint)
    eventEmitter.on('map:delete-waypoint', handleRemovePoint)
  }, [])
}
