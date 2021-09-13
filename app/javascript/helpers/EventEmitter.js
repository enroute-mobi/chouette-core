import { Subject } from 'rxjs'
import { filter, map } from 'rxjs/operators'

const subject = Symbol('subject')

export default class EventEmitter {
  constructor() {
    this[subject] = new Subject()
  }

  emit(event, ...args) {
    if (!Boolean(event)) {
      throw new Error(`Cannot emit event: falsey or empty event name`)
    }
    this[subject].next([event, args])
  }

  on(event, callback) {
    if (!Boolean(event)) {
      throw new Error(`Cannot add event listener: falsey or empty event name`)
    }

    return this[subject].pipe(
      filter(([emitEvent, _]) => event == emitEvent),
      map(([_, args]) => args)
    ).subscribe(args => {
      callback(...args)
    })
  }
}