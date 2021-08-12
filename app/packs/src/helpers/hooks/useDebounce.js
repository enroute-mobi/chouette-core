import { useCallback } from 'react'
import { debounce } from 'lodash'

const  useDebounce = (callback, debounceTime) =>
	useCallback(
		debounce(callback, debounceTime)
	)

export default useDebounce
