import { useState, useEffect } from 'react'
import { filter, map } from 'rxjs/operators'
import { isEqual } from 'lodash'

export default function useStore(
  store,
  mapStateToProps = state => state
) {
  const [state, setState] = useState(() => mapStateToProps(store.initialState))

  useEffect(() => {
    const sub = store.pipe(
      map(mapStateToProps),
      filter(newState => !isEqual(state, newState))
    ).subscribe(setState)

    // return () => sub.unsubsribe()
  }, [])

  return state
}