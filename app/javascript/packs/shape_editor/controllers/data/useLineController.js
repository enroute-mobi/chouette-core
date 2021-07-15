import { useEffect, useState } from 'react'
import useSWR from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { simplifyGeoJSON, submitFetcher, wktOptions } from '../../shape.helpers'
import { getSortedCoordinates } from '../../shape.selectors'
import store from '../../shape.store'
import { onWaypointsUpdate$ } from '../../shape.observables'

// Custom hook which responsability is to fetch a new LineString GeoJSON object based on state coordinates when shouldUpdateLine is set to true
export default function useLineController(isEdit, baseURL) {
  const [shouldUpdateLine, setShouldUpdateLine ] = useState(false)

  // Event handlers
  const onSuccess = async data => {
    setShouldUpdateLine(false)

    const lineFeature = new GeoJSON().readFeature(
      simplifyGeoJSON(data),
      wktOptions(isEdit)
    )

    const { line } = await store.getStateAsync()

    line.getGeometry().setCoordinates(
      lineFeature.getGeometry().getCoordinates()
    )
  }

  const onWaypointsUpdate = () => setShouldUpdateLine(true)

  useEffect(() => {
    onWaypointsUpdate$.subscribe(onWaypointsUpdate)
  }, [])

  return useSWR(
    () => shouldUpdateLine ? `${baseURL}/shapes/update_line` : null,
    async url => {
      const state = await store.getStateAsync()
      const payload = { coordinates: getSortedCoordinates(state) }

      return submitFetcher(url, 'PUT', payload)
    },
    { onSuccess }
  )
}