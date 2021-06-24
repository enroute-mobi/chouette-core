import { useState, useEffect } from 'react'
import { filter, map } from 'rxjs/operators'
import { isEqual } from 'lodash'

export default function useStore(
  store,
  mapStateToProps = state => state
) {
  const [state, setState] = useState(store.initialState)

  useEffect(()=> {
    store.pipe(
      map(mapStateToProps),
      filter(newState => !isEqual(state, newState))
    ).subscribe(setState)

    return () => {
      store.unsubsribe()
    }
  }, [])

  return [
    state,
    store.dispatch,
  ]
}