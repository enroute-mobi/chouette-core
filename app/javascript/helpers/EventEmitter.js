import { Subject } from 'rxjs'
import { filter, map } from 'rxjs/operators'

const subject = Symbol('subject')

export default class EventEmitter {
  constructor() {
    this[subject] = new Subject()
  }

  emit(event, ...args) {
    this[subject].next([event, args])
  }

  on(event, callback) {
    return this[subject].pipe(
      filter(([emitEvent, _]) => event == emitEvent),
      map(([_, args]) => args)
    ).subscribe(args => {
      callback(...args)
    })
  }
}