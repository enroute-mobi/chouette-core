import { useEffect, useState } from 'react'
import useSWR from 'swr'

import GeoJSON from 'ol/format/GeoJSON'

import { simplifyGeoJSON, submitFetcher } from '../../shape.helpers'
import { getLine, getSortedCoordinates } from '../../shape.selectors'
import store from '../../shape.store'
import eventEmitter from '../../shape.event-emitter'

// Custom hook which responsability is to fetch a new LineString GeoJSON object based on state coordinates when shouldUpdateLine is set to true
export default function useLineController(isEdit, baseURL) {
  const [shouldUpdateLine, setShouldUpdateLine ] = useState(false)

  // Event handlers
  const onSuccess = async data => {
    setShouldUpdateLine(false)

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

  const onWaypointsUpdate = () => setShouldUpdateLine(true)

  useEffect(() => {
    eventEmitter.on('waypoints:updated', onWaypointsUpdate)
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