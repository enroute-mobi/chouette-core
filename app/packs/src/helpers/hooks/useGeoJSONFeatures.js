import { useEffect, useState } from 'react'
import useSWR from 'swr'
import { isArray, isEmpty } from 'lodash'

import geoJSON from '../geoJSON'

const useGeoJSONFeatures = (
	urls,
	callback = () => {}
) => {
	const [loadingStatus, setLoadingStatus] = useState(() =>
		new Map(urls.map(url => [url, true]))
	)
	const [features, setFeatures] = useState()

	const doneFetching = Array.from(loadingStatus.entries()).every(([_key, isFetching]) => !isFetching)

	const onSuccess = (data, key) => {
		const fetchFeatures = isArray(data) ? data : [data]

		!isEmpty(fetchFeatures) && setFeatures(prevFeatures => [
			...(prevFeatures || []),
			...fetchFeatures.map(featureCollection => geoJSON.readFeatures(featureCollection)).flat()
		])

		setLoadingStatus(prevLoadingStatus =>
			new Map([
				...prevLoadingStatus.entries(),
				[key, false]
			])
		)
	}

	urls.forEach(url => {
		useSWR(url, { onSuccess, revalidateOnFocus: false })
	})

	useEffect(() => {
		doneFetching && callback(features)
	}, [doneFetching])

	return doneFetching ? features : null
}

export default useGeoJSONFeatures
