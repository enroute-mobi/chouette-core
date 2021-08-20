import { useEffect } from 'react'
import useSWR from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { simplifyGeoJSON, submitFetcher, wktOptions } from '../../shape.helpers'
import { getLine, getWaypointsCoords } from '../../shape.selectors'
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

    store.getState(state => {
      getLine(state).getGeometry().setCoordinates(newCoordinates)
    })
  }

  const { mutate: updateLine } = useSWR(
    url,
    async url => {
      const state = await store.getStateAsync()
      const payload = { coordinates: getWaypointsCoords(state) }

      return submitFetcher(url, 'PUT', payload)
    },
    { onSuccess, revalidateOnMount: false }
  )

  useEffect(() => {
    eventEmitter.on('waypoints:updated', updateLine)
  }, [])
}
