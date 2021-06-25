import { firstValueFrom, Subject } from 'rxjs'
import { first, scan, shareReplay, startWith } from 'rxjs/operators'
import { bindAll } from 'lodash'

export default class Store {
  constructor(
    reducer,
    initialState,
    mapDispatchToProps = _dispatch => ({})
  ) {
    this.subject = new Subject()

    this.initialState = {
      ...initialState,
      ...mapDispatchToProps(this.dispatch.bind(this))
    }

    this.$store = this.subject.pipe(
      scan(reducer, this.initialState),
      startWith(this.initialState),
      shareReplay(1)
    )

    bindAll(this, ['dispatch'])
  }

  pipe(observable) {
    return this.$store.pipe(observable)
  }

  getState(callback) {
    this.$store.pipe(first()).subscribe(callback)
  }

  getStateAsync() {
    return firstValueFrom(this.$store)
  }

  dispatch(action) {
    this.subject.next(action)
  }

  subscribe(setState) {
    this.$store.subscribe(setState)
  }

  unsubsribe() {
    this.$store.unsubsribe()
  }
}