import { useState } from 'react'
import useSWR from 'swr'
import { Circle, Fill, Stroke, Style } from 'ol/style'
import { head, isArray, last } from 'lodash'

import geoJSON from '../geoJSON'

const getStyles = () => ({
	line: new Style({
		stroke: new Stroke({
			color: '#007fbb',
			width: 2
		})
	}),
	edgePoint: new Style({
		image: new Circle({
			radius: 5,
			stroke: new Stroke({
				color: '#007fbb',
				width: 0
			}),
			fill: new Fill({
				color: '#007fbb',
				width: 0
			})
		})
	}),
	defaultPoint: new Style({
		image: new Circle({
			radius: 4,
			stroke: new Stroke({
				color: '#007fbb',
				width: 0
			}),
			fill: new Fill({
				color: '#ffffff',
				width: 0
			})
		})
	})
})

const useGeoJSONFeatures = url => {
	const [features, setFeatures] = useState()

	const styles = getStyles()

	const onSuccess = data => {
		const fetchFeatures = isArray(data) ? data : [data]

		setFeatures(() =>
			fetchFeatures.map(featureCollection => {
				const convertedFeatures = geoJSON.readFeatures(
					featureCollection,
				)

				const [line, ...waypoints] = convertedFeatures

				line.setStyle(styles.line)

				head(waypoints)?.setStyle(styles.edgePoint)
				last(waypoints)?.setStyle(styles.edgePoint)

				waypoints.forEach(w => {
					!w.getStyle() && w.setStyle(styles.defaultPoint)
				})

				return convertedFeatures
			}).flat()
		)
	}

	useSWR(url, { onSuccess })

	return features
}

export default useGeoJSONFeatures
