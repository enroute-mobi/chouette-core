import { useEffect } from 'react'
import { uniqueId } from 'lodash'

import Collection from 'ol/Collection'
import Polygon from 'ol/geom/Polygon';
import { Circle, Fill, Stroke, Style } from 'ol/style'
import {boundingExtent, getArea } from 'ol/extent';

import { getSource, getViewExtent } from '../../shape.selectors'
import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'
import { addMapInteractions, getLine, getWaypoints, lineId } from '../../shape.helpers'
import { onInit$, onAddPoint$ } from '../../shape.observables'

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
  const onInit = ([event, state]) => {
    const source = event.target.getSource()
    const features = source.getFeatures()
    const line = getLine(features)
    const waypoints = new Collection(getWaypoints(features), { unique: true })

    line.setId(lineId)

    waypoints.forEach(w => {
      w.setId(uniqueId('waypoint_'))
      w.set('type', 'waypoint')
    })

    addMapInteractions(source, state.map, waypoints)

    state.map.on('moveend', e => {
      const extent = getExtent(state.map)

      console.log('extent', getArea(extent))
    })

    // const poly = new Polygon(coords)

    //   console.log('poly', poly)

    // const extent = state.featuresLayer.addFeature(
    //   new Polygon(
    //     state.map.getView().calculateExtent(state.map.getSize())
    //   )
    // )
    // console.log('coords', coords)

    store.setLine(line)
    store.setWaypoints(waypoints)
  }

  const onAddPoint = ([event, _]) => {
    const { element: waypoint, target: waypoints } = event

    waypoint.set('type', 'constraint')
    waypoint.setStyle(constraintStyle)

    store.setWaypoints(waypoints)
  }

  const onRemovePoint = async waypoint => {
    const state = await store.getStateAsync()
    const { waypoints } = state
    const source = getSource(state)

    waypoints.remove(waypoint)
    source.removeFeature(waypoint)
    store.setWaypoints(waypoints)
  }

  const onWaypointZoom = async waypoint => {
    const { map } = await store.getStateAsync()

    map.getView().fit(waypoint.getGeometry(), { maxZoom: 17 })
  }

  useEffect(() => {
    const subs = [
      onInit$.subscribe(onInit),
      onAddPoint$.subscribe(onAddPoint),
      eventEmitter.on('map:zoom-to-waypoint', onWaypointZoom),
      eventEmitter.on('map:delete-waypoint', onRemovePoint)
    ]
     
    return () => subs.forEach(sub => sub.unsubscribe())
  }, [])
}
