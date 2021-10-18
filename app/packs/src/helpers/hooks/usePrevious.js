import { useEffect, useRef } from 'react'

const usePrevious = value => {
  const ref = useRef()

  useEffect(() => {
    ref.current = value
  })

  return ref.current
}

export default usePrevious

// https://blog.logrocket.com/how-to-get-previous-props-state-with-react-hooks/