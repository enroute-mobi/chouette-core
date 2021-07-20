import { fromEvent } from 'rxjs'
import { distinctUntilKeyChanged, filter, first, skip, switchMap  } from 'rxjs/operators'
import store from './shape.store'

const onCollectionUpdate = eventName =>
  store.pipe(
    distinctUntilKeyChanged('waypoints'),
    skip(1),
    switchMap(state => fromEvent(state.waypoints, eventName))
  )

export const onMapInit$ = store.pipe(
  distinctUntilKeyChanged('map'),
  filter(state => !!state.map),
  first()
)

export const onReceiveFeatures$ = store.pipe(
  distinctUntilKeyChanged('features'),
  filter(state => state.features.length > 0),
  first()
)

export const onAddPoint$ = onCollectionUpdate('add')

export const onRemovePoint$ = onCollectionUpdate('remove')

export const onWaypointsUpdate$ = onCollectionUpdate('change')