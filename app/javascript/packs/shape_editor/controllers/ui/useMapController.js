import { useEffect } from 'react'
import { fromEvent } from 'rxjs'
import { distinct, distinctUntilKeyChanged, filter, pairwise, pluck, skip, switchMap, tap } from 'rxjs/operators'
import { uniqueId } from 'lodash'

import { Circle, Fill, Stroke, Style } from 'ol/style'

import { getSource } from '../../shape.selectors'
import store from '../../shape.store'
import { addMapInteractions, getLine, getWaypoints, lineId } from '../../shape.helpers'

const constraintStyle = new Style({
  image: new Circle({
    radius: 2.5,
    stroke: new Stroke({ color: 'black', width: 1 }),
    fill: new Fill({ color: 'rgba(255, 255, 255, 0.5)' })
   })
})
  
export default function useMapInteractions() {
  // Helpers
  const getStoreAttribute$ = name => source =>
    source.pipe(pluck(name), distinct())

  // Event Handlers
  const onInit$ = store.pipe(
    getStoreAttribute$('featuresLayer'),
    switchMap(featuresLayer => fromEvent(featuresLayer, 'change:source')),
    tap(({ target }) => {
      const source = target.getSource()
      const features = source.getFeatures()
      const line = getLine(features)
      const waypoints = getWaypoints(features)

      line.setId(lineId)

      waypoints.forEach(w => {
        w.setId(uniqueId('waypoint_'))
        w.set('type', 'waypoint')
      })

      store.setLine(line)
      store.setWaypoints(waypoints)
    })
  )

  const onDrawEnd$ = store.pipe(
    getStoreAttribute$('draw'),
    skip(1),
    switchMap(draw => fromEvent(draw, 'drawend')),
    tap(({ feature: waypoint }) => {
      waypoint.set('type', 'constraint')
      waypoint.setStyle(constraintStyle)
      store.addNewPoint(waypoint)
      store.setAttributes({ shouldUpdateLine: true })
    })
  )

  const onModifyEnd$ = store.pipe(
    getStoreAttribute$('modify'),
    skip(1),
    switchMap(modify => fromEvent(modify, 'modifyend')),
    tap(({ features }) => {
      const waypoint = features.getArray()[0]

      store.moveWaypoint(
        waypoint.getId(),
        waypoint.getGeometry().getCoordinates()
      )
      store.setAttributes({ shouldUpdateLine: true })
    })
  )

  const onNewPoint$ = store.pipe(
    distinctUntilKeyChanged('waypoints'),
    pairwise(),
    filter(([prevState, newState]) => prevState.waypoints.length < newState.waypoints.length),
    tap(([_, state]) => {
      addMapInteractions(getSource(state), state)
    })
  )

  useEffect(() => {
    const subs = [
      onInit$.subscribe(),
      onDrawEnd$.subscribe(),
      onModifyEnd$.subscribe(),
      onNewPoint$.subscribe(),
    ]
     
    return () => subs.forEach(sub => sub.unsubscribe())
  }, [])
}