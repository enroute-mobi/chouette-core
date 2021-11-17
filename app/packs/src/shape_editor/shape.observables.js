import { fromEvent, merge } from 'rxjs'
import { flow, get, isFunction, isString } from 'lodash'
import { distinctUntilKeyChanged, filter, first, map, pluck, skip, switchMap } from 'rxjs/operators'

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
    has$('waypoints'),
    switchMap(state => fromEvent(state.waypoints, eventName))
  )

export const onWaypointsUpdate$ = merge(
  onCollectionUpdate('add'),
  onCollectionUpdate('remove'),
  onCollectionUpdate('change')
)

const getZoom = e => e.map.getView().getZoom()

export const onMapZoom$ = store.pipe(
  has$('map'),
  pluck('map'),
  switchMap(map_ => fromEvent(map_, 'movestart').pipe(
    map(startEvent => [map_, getZoom(startEvent)])
  )),
  switchMap(([map_, startCoords]) => fromEvent(map_, 'moveend').pipe(
    map(endEvent => [startCoords, getZoom(endEvent)])
  )),
  filter(([startZoom, endZoom]) => startZoom != endZoom),
  map(([_, zoom]) => zoom)
)

export const onReceivePermissions$ = store.pipe(
  distinctUntilKeyChanged('permissions'),
  skip(1)
)
