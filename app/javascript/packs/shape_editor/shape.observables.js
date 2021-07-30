import { fromEvent } from 'rxjs'
import { filter, first, map, switchMap, skipUntil  } from 'rxjs/operators'
import store from './shape.store'
import { getLine } from './shape.selectors'

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
/* TODO add observables to follow the folling chain of eventts: 
  - map click
  - check if event coordinate are below a chosen distance from line (use turf helper function to compute the distance)
  - add last listener of map pointer move (takeUntil map:mousevent) 
  - dispatch drawend event or use one of draw functions to trigger a draw event
  - setDistanceFromStart helper & ad coordinates parameter(we can use the event coordinates in this case)
  */
export const onDrawEnd$ = store.pipe(
  filter(state => !!state.map && !!state.draw && getLine(state)),
  first(),
  switchMap(state => fromEvent(state.map, 'click').pipe(
    filter(event => {
      console.log('click', getLine(state).getGeometry().intersectsCoordinate(event.coordinate))
      return getLine(state).getGeometry().intersectsCoordinate(event.coordinate)
    }),
    map(event => [state, event])
  )),
  
  // switchMap(([state, event]) => {
    
  //   return fromEvent(state.map, 'pointermove').pipe(
  //     debounceTime()
  //   )
  // })

)

onDrawEnd$.subscribe(data => console.log('drawend', data))