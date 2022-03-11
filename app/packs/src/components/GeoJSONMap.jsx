import React from 'react'
import { render } from 'react-dom'

import { useGeoJSONFeatures } from '../helpers/hooks'
import MapWrapper from './MapWrapper'

const App = ({ urls, callback }) => {
	const features = useGeoJSONFeatures(urls, callback)

	return <MapWrapper features={features} />
}

export default {
	init(urls, selector, callback = () => {}) {
		
		render(
			<App urls={urls} callback={callback} />,
			document.getElementById(selector)
		)
	}
}
