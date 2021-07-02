import { useEffect, useState } from 'react'
import useSWR from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { baseURL, simplifyGeoJSON, wktOptions } from '../../shape.helpers'
import { getSortedCoordinates } from '../../shape.selectors'
import store from '../../shape.store'
import { onWaypointsUpdate$ } from '../../shape.observables'

// Custom hook which responsability is to fetch a new LineString GeoJSON object based on state coordinates when shouldUpdateLine is set to true
export default function useLineController() {
  const [shouldUpdateLine, setShouldUpdateLine ] = useState(false)

  // Fetcher
  const fetcher = async url => {
    const state = await store.getStateAsync()
    const coordinates = getSortedCoordinates(state)

    const response = await fetch(url, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').attributes.content.value
      },
      body: JSON.stringify({ coordinates })
    })

    return response.json()
  }
  
  // Event handlers
  const onSuccess = async data => {
    setShouldUpdateLine(false)

    const lineFeature = new GeoJSON().readFeature(
      simplifyGeoJSON(data),
      wktOptions
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
    () => shouldUpdateLine ? `${baseURL}/update_line` : null,
    fetcher,
    { onSuccess }
  )
}