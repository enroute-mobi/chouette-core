import React from 'react'
import { render } from 'react-dom'

import { useGeoJSONFeatures } from '../helpers/hooks'
import MapWrapper from './MapWrapper'

const App = ({ url, callback }) => {
	const features = useGeoJSONFeatures(url, callback)

	return (
		<div className="ol-map">
			<MapWrapper features={features} />
		</div>
	)
}

export default {
	init(url, selector, callback = () => {}) {
		render(
			<App url={url} callback={callback} />,
			document.getElementById(selector)
		)
	}
}
