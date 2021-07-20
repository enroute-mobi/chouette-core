import { useEffect } from 'react'
import { uniqueId } from 'lodash'

import Collection from 'ol/Collection'
import Polygon from 'ol/geom/Polygon';
import { Circle, Fill, Stroke, Style } from 'ol/style'
import {boundingExtent, getArea } from 'ol/extent'
import VectorLayer from 'ol/layer/Vector'
import { defaults as defaultControls } from 'ol/control'
import VectorSource from 'ol/source/Vector'

import { getInteractiveSource } from '../../shape.selectors'
import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'
import { addMapInteractions, getLine, getWaypoints, lineId } from '../../shape.helpers'

const constraintStyle = new Style({
  image: new Circle({
    radius: 2.5,
    stroke: new Stroke({ color: 'black', width: 1 }),
    fill: new Fill({ color: 'rgba(255, 255, 255, 0.5)' })
   })
})

const getExtent = map => {
  const coords = map.getView().calculateExtent(map.getSize())
  const extent = boundingExtent(coords)
  return extent
}
  
export default function useMapInteractions() {
  // Event Handlers
  const onMapInit = map => {
    const layers = map.getLayers()

    const interactiveLayer = layers.getArray()[1]
  
    interactiveLayer.set('type', 'interactive')

    const staticLayer = new VectorLayer({
      source: new VectorSource(),
    })

    staticLayer.set('type', 'static')

    map.getLayers().insertAt(1, staticLayer) // inserting static layer juste below the interactive one
  }

  const onReceiveFeatures = state => {
    const source = getInteractiveSource(state)
    const line = getLine(state.features)
    const waypoints = new Collection(getWaypoints(state.features), { unique: true })

    waypoints.on('change', e => {
      console.log('waypoints change')
    })

    line.setId(lineId)

    waypoints.forEach(w => {
      w.setId(uniqueId('waypoint_'))
      w.set('type', 'waypoint')
    })

    addMapInteractions(source, state.map, waypoints)

    // state.map.on('moveend', e => {
    //   const extent = getExtent(state.map)

    //   console.log('extent', getArea(extent))
    // })

    // const poly = new Polygon(coords)

    //   console.log('poly', poly)

    // const extent = state.featuresLayer.addFeature(
    //   new Polygon(
    //     state.map.getView().calculateExtent(state.map.getSize())
    //   )
    // )
    // console.log('coords', coords)
    store.setAttributes({ line, waypoints })
  }

  const onAddPoint = event => {
    const { element: waypoint, target: waypoints } = event

    waypoint.set('type', 'constraint')
    waypoint.setStyle(constraintStyle)

    store.setAttributes({ waypoints })
  }

  const onRemovePoint = async waypoint => {
    const state = await store.getStateAsync()
    const { waypoints } = state
    const source = getInteractiveSource(state)

    waypoints.remove(waypoint)
    source.removeFeature(waypoint)
    store.setAttributes({ waypoints })
  }

  const onWaypointZoom = async waypoint => {
    const { map } = await store.getStateAsync()

    map.getView().fit(waypoint.getGeometry(), { maxZoom: 17 })
  }

  useEffect(() => {
    eventEmitter.on('map:init', onMapInit)
    eventEmitter.on('shape:receive-features', onReceiveFeatures)
    eventEmitter.on('map:add-point', onAddPoint)
    eventEmitter.on('map:zoom-to-waypoint', onWaypointZoom)
    eventEmitter.on('map:delete-waypoint', onRemovePoint)
  }, [])
}
