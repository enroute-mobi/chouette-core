import { useEffect } from 'react'
import { uniqueId } from 'lodash'

import { Circle, Fill, Stroke, Style } from 'ol/style'
import { Draw, Modify, Snap } from 'ol/interaction'
import VectorLayer from 'ol/layer/Vector'
import VectorSource from 'ol/source/Vector'

import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'
import { lineId } from '../../shape.helpers'
import { Collection } from 'ol'

const getStyles = () => ({
  points: {
    shapeWaypoint: new Style({
      image: new Circle({
        radius: 6,
        stroke: new Stroke({ color: 'white', width: 1 }),
        fill: new Fill({ color: 'red' })
      })
    }),
    shapeConstraint: new Style({
      image: new Circle({
        radius: 6,
        stroke: new Stroke({ color: 'red', width: 1 }),
        fill: new Fill({ color: 'white' })
      })
    }),
    route: new Style({
      image: new Circle({
        radius: 5,
        stroke: new Stroke({ color: 'black', width: 0.75 }),
        fill: new Fill({ color: 'rgba(255, 255, 255, 0.5)' })
      })
    }),
  },
  lines: {
    route: new Style({
      stroke: new Stroke({
        color: 'black',
        width: 1,
        lineDash: [6,6],
        lineDashOffset: 6
      })
    }),
    shape: new Style({
      stroke: new Stroke({
        color: 'red',
        width: 1.5
      })
    })
  }
})

export default function useMapInteractions() {
  const styles = getStyles()

  // Event Handlers
  const onMapInit = async map => {
    const state = await store.getStateAsync()
    const layers = map.getLayers()

    layers.item(1).set('type', 'interactive')

    const staticLayer = new VectorLayer({
      source: new VectorSource({ features: state.routeFeatures }),
      properties: { type: 'static' }
    })

    layers.insertAt(1, staticLayer) // inserting static layer juste below the interactive one

    store.setAttributes({ map })
  }

  const onReceiveShapeFeatures = async event => {
    const state = await store.getStateAsync()
    const { map } = state
    const featureCollection = event.target

    const [line, ...points] = featureCollection.getArray()

    const waypoints = new Collection(points)
  
    line.setId(lineId)

    line.setStyle(styles.lines.shape)

    points.forEach(w => {
      w.setId(uniqueId('waypoint_'))
      w.set('type', 'waypoint')

      console.log('type', w.getProperties())
      // const style = w.get('type') == 'waypoint' ? 'shapeWaypoint' : 'shapeConstraint'
      w.setStyle(styles.points.shapeWaypoint)
    })

    const modify = new Modify({ features: waypoints })
    const draw = new Draw({ features: event.target, type: 'Point' })
    const snap = new Snap({ features: event.target })
    const interactions = [modify, draw, snap]

    draw.on('drawend', () => featureCollection.changed())
    modify.on('modifyend', () => featureCollection.changed())

    interactions.forEach(i => map.addInteraction(i))
  }

  const onAddPoint = async event => {
    const { element: waypoint, target: shapeFeatures } = event

    waypoint.set('type', 'constraint')
    waypoint.setStyle(styles.points.shapeConstraint)
    store.setAttributes({ shapeFeatures })
  }

  const onRemovePoint = async waypoint => {
    const { shapeFeatures } = await store.getStateAsync()

    shapeFeatures.remove(waypoint)
    shapeFeatures.changed()
    store.setAttributes({ shapeFeatures })
  }

  const onWaypointZoom = async waypoint => {
    const { map } = await store.getStateAsync()

    map.getView().fit(waypoint.getGeometry(), { maxZoom: 17 })
  }

  useEffect(() => {
    eventEmitter.on('map:init', onMapInit)
    eventEmitter.on('shape:receive-features', onReceiveShapeFeatures)
    eventEmitter.on('map:add-point', onAddPoint)
    eventEmitter.on('map:zoom-to-waypoint', onWaypointZoom)
    eventEmitter.on('map:delete-waypoint', onRemovePoint)
  }, [])
}
