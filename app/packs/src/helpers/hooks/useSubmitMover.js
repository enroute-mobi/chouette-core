import { useEffect } from 'react'

import SubmitMover from '../SubmitMover'

export default function useSubmitMover() {
	useEffect(() => { SubmitMover.init() }, [])
}
