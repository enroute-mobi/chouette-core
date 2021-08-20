import { useEffect } from 'react'
import { debounce, uniqueId } from 'lodash'

import { Modify, Snap } from 'ol/interaction'
import VectorLayer from 'ol/layer/Vector'
import VectorSource from 'ol/source/Vector'

import { getLine, getWaypoints } from '../../shape.selectors'
import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'
import { getWaypointToInsertAttributes, getStyles, lineId } from '../../shape.helpers'

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

  const onReceiveShapeFeatures = async _event => {
    const state = await store.getStateAsync()
    const { map, shapeFeatures } = state

    const line = getLine(state)
    const waypoints = getWaypoints(state)

    line.setId(lineId)

    const shapeLineStyleFunc = debounce(styles.lines.shape, 100, { leading: true })
    line.setStyle(shapeLineStyleFunc)


    waypoints.forEach((w, i) => {
      w.setId(uniqueId('waypoint_'))

      const waypointStyle = w.get('type') == 'waypoint' ? 'shapeWaypoint' : 'shapeConstraint'
      w.setStyle(styles.points[waypointStyle])
    })

    const modify = new Modify({ features: shapeFeatures })
    const snap = new Snap({ features: shapeFeatures })
    const interactions = [modify, snap]

    store.setAttributes({ modify, shapeFeatures })

    interactions.forEach(i => map.addInteraction(i))
  }

  const onReceiveRouteFeatures = event => {
    const features = event.target.getArray()
    const [line, ...waypoints] = features

    line.setStyle(styles.lines.route)

    waypoints.forEach(w => {
      w.setStyle(styles.points.route)
    })
  }

  const onLineModify = async coords => {
    const { shapeFeatures } = await store.getStateAsync()
    const { waypoint, insertIndex } = await getWaypointToInsertAttributes(coords)

    shapeFeatures.insertAt(insertIndex, waypoint)
    
    store.setAttributes({ shapeFeatures })
  }

  const onRemovePoint = async waypoint => {
    const { shapeFeatures } = await store.getStateAsync()

    shapeFeatures.remove(waypoint)

    store.setAttributes({ shapeFeatures })
  }

  const onWaypointZoom = async waypoint => {
    const { map } = await store.getStateAsync()

    map.getView().fit(waypoint.getGeometry(), { maxZoom: 17 })
  }

  useEffect(() => {
    eventEmitter.on('map:init', onMapInit)
    eventEmitter.on('route:receive-features', onReceiveRouteFeatures)
    eventEmitter.on('shape:receive-features', onReceiveShapeFeatures)
    eventEmitter.on('line:modify', onLineModify)
    eventEmitter.on('map:zoom-to-waypoint', onWaypointZoom)
    eventEmitter.on('map:delete-waypoint', onRemovePoint)
  }, [])
}
