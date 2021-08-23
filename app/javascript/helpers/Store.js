import { firstValueFrom, Subject } from 'rxjs'
import { filter, first, scan, shareReplay, startWith } from 'rxjs/operators'

import { debounce, has, isObject } from 'lodash'
export default class Store extends Subject {
  constructor(
    reducer,
    initialState,
    mapDispatchToProps = _dispatch => ({})
  ) {
    super()

    this.initialState = initialState
    this.actionDispatcher = new Subject()

    const funcs = mapDispatchToProps(this.dispatch.bind(this))

    for (const name in funcs) {
      this[name] = funcs[name]
    }

    this.store$ = this.actionDispatcher.pipe(
      filter(action => {
        const isValid = isObject(action) && has(action, 'type')

        if (!isValid) console.warn('action is not valid', action)

        return isValid
      }),
      scan(reducer,  this.initialState),
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
