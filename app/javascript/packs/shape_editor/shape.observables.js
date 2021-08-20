import { fromEvent, merge } from 'rxjs'
import { flow, get, isFunction, isString } from 'lodash'
import { filter, first, map, pluck, switchMap } from 'rxjs/operators'

import store from './shape.store'

const has$ = pathOrSelector => {
  let selectorFunc

  if (isString(pathOrSelector)) {
    selectorFunc = state => get(state, pathOrSelector)
  } else if (isFunction(pathOrSelector)) {
    selectorFunc = pathOrSelector
  } else {
    throw('argument must be a string or a selector function')
  }

  return filter(flow(selectorFunc, Boolean))
}

const onCollectionUpdate = eventName =>
  store.pipe(
    has$('shapeFeatures'),
    switchMap(state => fromEvent(state.shapeFeatures, eventName))
  )

export const onReceiveShapeFeatures$ = store.pipe(
  has$('shapeFeatures'),
  switchMap(state => fromEvent(state.shapeFeatures, 'receiveFeatures')),
  first()
)

export const onReceiveRouteFeatures$ = store.pipe(
  switchMap(state => fromEvent(state.routeFeatures, 'receiveFeatures')),
  first()
)

const onModify$ = store.pipe(
  has$('modify'),
  pluck('modify'),
  switchMap(modify => fromEvent(modify, 'modifystart').pipe(
    map(event => [modify, event])
  ))
)

export const onLineModify$ = onModify$.pipe(
  filter(([_, startEvent]) => startEvent.features.item(0).getGeometry().getType() == 'LineString'),
  switchMap(([modify, startEvent]) => fromEvent(modify, 'modifyend').pipe(
    first(),
    map(endEvent => [startEvent.mapBrowserEvent.coordinate, endEvent.mapBrowserEvent.coordinate])
  ))
)

const onWaypointsModify$ = onModify$.pipe(
  filter(([_, startEvent]) => startEvent.features.item(0).getGeometry().getType() == 'Point'),
  switchMap(([modify, _]) => fromEvent(modify, 'modifyend').pipe(first()))
)

export const onWaypointsUpdate$ = merge(
  onWaypointsModify$,
  onCollectionUpdate('add'),
  onCollectionUpdate('remove'),
  onCollectionUpdate('change')
)
