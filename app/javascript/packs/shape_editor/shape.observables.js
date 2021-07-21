import { fromEvent } from 'rxjs'
import { first, switchMap  } from 'rxjs/operators'
import store from './shape.store'

const onCollectionUpdate = eventName =>
  store.pipe(
    switchMap(state => fromEvent(state.shapeFeatures, eventName))
  )

export const onReceiveShapeFeatures$ = store.pipe(
  switchMap(state => fromEvent(state.shapeFeatures, 'receiveFeatures')),
  first()
)

export const onReceiveRouteFeatures$ = store.pipe(
  switchMap(state => fromEvent(state.routeFeatures, 'receiveFeatures')),
  first()
)

export const onAddPoint$ = onCollectionUpdate('add')

export const onRemovePoint$ = onCollectionUpdate('remove')

export const onWaypointsUpdate$ = onCollectionUpdate('change')