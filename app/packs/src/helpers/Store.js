import { firstValueFrom, Subject } from 'rxjs'
import { filter, first, scan, shareReplay, startWith } from 'rxjs/operators'

import { debounce, has, isObject } from 'lodash'

import { isDev } from './env'
export default class Store extends Subject {
  constructor(
    reducer,
    initialState,
    actionsCreator = {}
  ) {
    super()

    this.initialState = initialState
    this.actionDispatcher = new Subject()

    for (const name in actionsCreator) {
      this[name] = (...args) => this.dispatch(actionsCreator[name](...args))
    }

    this.store$ = this.actionDispatcher.pipe(
      filter(action => {
        const isValid = isObject(action) && has(action, 'type')

        !isValid && isDev && console.warn('action is not valid', action)

        return isValid
      }),
      scan(
        (state, action) => {
          const newState = reducer(state, action)

          if (isDev) {
            console.group(action.type)
            console.log('%cprev state', 'color: #c033d6;', state)
            console.log('%caction', 'color: #26bfbf;', action)
            console.log('%cnew state', 'color: #26bf59;', newState)
            console.groupEnd()
          }

          return newState
        },
        this.initialState
      ),
      startWith(this.initialState),
      shareReplay(1)
    )

    this.store$.subscribe(state => {
      this.next(state)
    })
  }

  getState(callback) {
    this.store$.pipe(first()).subscribe(callback)
  }

  getStateAsync() {
    return firstValueFrom(this.store$)
  }

  // To be use with care since it is a blocking function
  getStateSync() {
    let syncState
    const getState = debounce(this.getState.bind(this), 100, { leading: true })
    const setSyncState = state => { syncState = state }

    do { getState(setSyncState) } while(!syncState)

    return syncState
  }

  dispatch(action) {
    this.actionDispatcher.next(action)
  }
}
