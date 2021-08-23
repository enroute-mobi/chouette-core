import { useEffect } from 'react'
import useSWR from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { getLine, getWaypointsCoords , simplifyGeoJSON, submitFetcher, wktOptions } from '../../shape.helpers'
import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'

// Custom hook which responsability is to fetch a new LineString GeoJSON object based on state coordinates when shouldUpdateLine is set to true
export default function useLineController(_isEdit, baseURL) {
  const url = `${baseURL}/shapes/update_line`

  // Event handlers
  const onSuccess = async data => {
    const newCoordinates = new GeoJSON().readFeature(
      simplifyGeoJSON(data),
      wktOptions
    ).getGeometry().getCoordinates()

    const { map } = await store.getStateAsync()
    getLine(map).getGeometry().setCoordinates(newCoordinates)
  }

  const { mutate: updateLine } = useSWR(
    url,
    async url => {
      const { map } = await store.getStateAsync()
      const payload = { coordinates: getWaypointsCoords(map) }

      return submitFetcher(url, 'PUT', payload)
    },
    { onSuccess, revalidateOnMount: false }
  )

  useEffect(() => {
    eventEmitter.on('waypoints:updated', updateLine)
  }, [])
}
