import { fromEvent, merge } from 'rxjs'
import { distinct, distinctUntilKeyChanged, filter, map, pairwise, pluck, skip, switchMap, tap, withLatestFrom } from 'rxjs/operators'
import store from './shape.store'

const getStoreAttribute$ = name => source => source.pipe(pluck(name), distinct())

const onCollectionUpdate = eventName =>
  store.pipe(
    distinctUntilKeyChanged('waypoints'),
    skip(1),
    switchMap(state =>
      fromEvent(state.waypoints, eventName).pipe(
        map(event => [event, state])
      )
    )
  )

export const onInit$ = store.pipe(
  distinctUntilKeyChanged('featuresLayer'),
  switchMap(state =>
    fromEvent(state.featuresLayer, 'change:source').pipe(
      map(event => [event, state])
    )
  )
)

export const onMovePoint$ = store.pipe(
  getStoreAttribute$('modify'),
  skip(1),
  switchMap(modify => fromEvent(modify, 'modifyend'))
)

export const onAddPoint$ = onCollectionUpdate('add')

export const onRemovePoint$ = onCollectionUpdate('remove')

export const onAddOrDeletePoint$ = onCollectionUpdate('change:length')

export const onWaypointsUpdate$ = merge(onMovePoint$, onAddOrDeletePoint$)