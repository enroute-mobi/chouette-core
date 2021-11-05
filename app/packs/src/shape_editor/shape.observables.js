import { fromEvent, merge } from 'rxjs'
import { flow, get, isEmpty, isFunction, isString } from 'lodash'
import { debounceTime, distinctUntilKeyChanged, filter, map, skip, skipUntil, switchMap, tap } from 'rxjs/operators'

import store from './shape.store'

const has$ = pathOrSelector => {
  let selectorFunc

  if (isString(pathOrSelector)) {
    selectorFunc = state => get(state, pathOrSelector)
  } else if (isFunction(pathOrSelector)) {
    selectorFunc = pathOrSelector
  } else {z
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

const mapWithFeatures$ = store.pipe(
  has$('map'),
  skipUntil(store.pipe(has$('geometry'))),
)

export const onMapZoom$ = mapWithFeatures$.pipe(
  switchMap(({ map }) => fromEvent(map.getView(), 'change:resolution').pipe(
    debounceTime(100)
  ))
)

export const onMapMove$ = mapWithFeatures$.pipe(
  switchMap(({ map }) => fromEvent(map, 'moveend'))
)

export const onLineStringModify$ = mapWithFeatures$.pipe(
  has$('modify'),
  switchMap(state => fromEvent(state.modify, 'modifystart').pipe(
    map(startEvent => {
      const { pixel, coordinate: startCoords } = startEvent.mapBrowserEvent
      const features = state.map.getFeaturesAtPixel(pixel, { layerFilter: l => l.get('waypoints') })
      const moveWaypoint = e => features.forEach(w => w.getGeometry().setCoordinates(e.coordinate))

      return { ...state, features, moveWaypoint, startCoords }
    }),
    tap(state => { state.map.on('pointermove', state.moveWaypoint) })
  )),
  switchMap(state => fromEvent(state.modify, 'modifyend').pipe(
    tap(() => { state.map.un('pointermove', state.moveWaypoint) }),
    map(endEvent => {
      const { features, startCoords, waypoints } = state
      if (isEmpty(features)) {
        return { type: 'ADD_WAYPOINT', startCoords, endCoords: endEvent.mapBrowserEvent.coordinate }
      } else {
        return { type: 'UPDATE_LINESTRING', waypoints }
      }
    })
  ))
)

export const onReceivePermissions$ = store.pipe(
  distinctUntilKeyChanged('permissions'),
  skip(1)
)
