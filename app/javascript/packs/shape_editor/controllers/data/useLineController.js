import { useEffect } from 'react'
import useSWR, { mutate } from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { simplifyGeoJSON, submitFetcher } from '../../shape.helpers'
import { getLine, getSortedCoordinates } from '../../shape.selectors'
import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'

// Custom hook which responsability is to fetch a new LineString GeoJSON object based on state coordinates when shouldUpdateLine is set to true
export default function useLineController(_isEdit, baseURL) {
  const url = `${baseURL}/shapes/update_line`

  // Event handlers
  const onSuccess = async data => {
    const newCoordinates = new GeoJSON().readFeature(
      simplifyGeoJSON(data),
      {
        dataProjection: 'EPSG:4326',
        featureProjection: 'EPSG:3857'
      }
    ).getGeometry().getCoordinates()

    store.getState(state => {
      getLine(state).getGeometry().setCoordinates(newCoordinates)
    })
  }

  useEffect(() => {
    eventEmitter.on('waypoints:updated', () => mutate(url))
  }, [])

  return useSWR(
    url,
    async url => {
      const state = await store.getStateAsync()
      const payload = { coordinates: getSortedCoordinates(state) }

      return submitFetcher(url, 'PUT', payload)
    },
    { onSuccess, revalidateOnMount: false }
  )
}