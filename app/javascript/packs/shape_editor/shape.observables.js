import { fromEvent, merge } from 'rxjs'
import { flow, get, isFunction, isString } from 'lodash'
import { filter, switchMap } from 'rxjs/operators'

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
