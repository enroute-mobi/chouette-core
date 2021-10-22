import React from 'react'
import { render } from 'react-dom'

import { useGeoJSONFeatures } from '../helpers/hooks'
import MapWrapper from './MapWrapper'

const App = ({ url }) => {
	const features = useGeoJSONFeatures(url)

	return (
		<div className="ol-map">
			<MapWrapper features={features} />
		</div>
	)
}

export default {
	init(url, selector) {
		render(
			<App url={url} />,
			document.getElementById(selector)
		)
	}
}
