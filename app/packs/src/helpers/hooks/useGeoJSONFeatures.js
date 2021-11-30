import { useState } from 'react'
import useSWR from 'swr'
import { isArray, isEmpty } from 'lodash'

import geoJSON from '../geoJSON'

const useGeoJSONFeatures = (
	url,
	callback = () => {}
) => {
	const [features, setFeatures] = useState()

	const onSuccess = data => {
		const fetchFeatures = isArray(data) ? data : [data]

		!isEmpty(fetchFeatures) && setFeatures(() =>
			fetchFeatures.map(featureCollection => {
				const convertedFeatures = geoJSON.readFeatures(featureCollection)

				callback(convertedFeatures)

				return convertedFeatures
			}).flat()
		)
	}

	useSWR(url, { onSuccess, revalidateOnFocus: false })

	return features
}

export default useGeoJSONFeatures
